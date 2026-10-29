import 'dart:async';

import 'package:bacakomik_app/core/error/failures.dart';
import 'package:bacakomik_app/features/bookmark/domain/usecases/refresh_bookmark.dart';
import 'package:bacakomik_app/features/bookmark/presentation/bloc/bookmark_refresh_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'library_test.dart' show RecordingNotifier, bookmark;

typedef _Result = Either<Failure, RefreshResult>;

const _unchanged = Right<Failure, RefreshResult>((
  saved: null,
  historyChanged: false,
  failure: null,
));

/// Refreshes that finish when the test says so, recording how many run at
/// once in total and per source.
class _Source {
  final pending = <String, Completer<_Result>>{};
  final tokens = <String, RefreshCancelToken>{};
  final started = <String>[];
  var maxRunning = 0;
  final maxPerSource = <String, int>{};
  final _running = <String>{};

  Future<_Result> call(String key, RefreshCancelToken token) {
    started.add(key);
    tokens[key] = token;
    _running.add(key);
    maxRunning = _running.length > maxRunning ? _running.length : maxRunning;
    final source = key.split(':').first;
    final perSource = _running.where((k) => k.startsWith('$source:')).length;
    maxPerSource.update(
      source,
      (n) => perSource > n ? perSource : n,
      ifAbsent: () => perSource,
    );
    final completer = pending[key] = Completer<_Result>();
    return completer.future.whenComplete(() => _running.remove(key));
  }

  void finish(String key, [_Result result = _unchanged]) =>
      pending.remove(key)!.complete(result);
}

void main() {
  late _Source source;
  late RecordingNotifier notifier;
  late List<(String, bool)> results;
  late BookmarkRefreshQueue queue;

  BookmarkRefreshQueue make({Duration timeout = const Duration(seconds: 90)}) =>
      BookmarkRefreshQueue(
        refresh: source.call,
        notifier: notifier,
        timeout: timeout,
        onResult: (key, result, {required late}) => results.add((key, late)),
      );

  setUp(() {
    source = _Source();
    notifier = RecordingNotifier();
    results = [];
    queue = make();
  });

  tearDown(() => queue.dispose());

  test('runs up to three at once, one per source', () async {
    final run = queue.add(['x:1', 'x:2', 'y:1', 'z:1', 'w:1', 'y:2']);
    await pumpEventQueue();

    // x:2 waits for x:1; w:1 for a free slot.
    expect(source.started, ['x:1', 'y:1', 'z:1']);

    source.finish('y:1');
    await pumpEventQueue();
    // The first queued comic whose source is free: x:2 is still blocked.
    expect(source.started, ['x:1', 'y:1', 'z:1', 'w:1']);

    source.finish('x:1');
    await pumpEventQueue();
    expect(source.started.last, 'x:2');

    while (source.pending.isNotEmpty) {
      source.finish(source.pending.keys.first);
      await pumpEventQueue();
    }
    await run;

    expect(source.started, hasLength(6));
    expect(source.maxRunning, 3);
    expect(source.maxPerSource.values.every((n) => n == 1), isTrue);
    expect(notifier.calls.first, '0/6');
    expect(notifier.calls.last, 'finish -');
    expect(queue.refreshing.value, isFalse);
  });

  test('a merged comic waits until all its sources are free', () async {
    queue.dispose();
    queue = BookmarkRefreshQueue(
      refresh: source.call,
      notifier: notifier,
      onResult: (key, result, {required late}) => results.add((key, late)),
      sourcesOf: (key) => key == 'x:m' ? {'x', 'y'} : {key.split(':').first},
    );

    final run = queue.add(['y:1', 'x:m', 'x:1', 'z:1']);
    await pumpEventQueue();
    // x:m also reads y, busy with y:1; x:1 goes first, so x:m waits on x too.
    expect(source.started, ['y:1', 'x:1', 'z:1']);

    source.finish('y:1');
    await pumpEventQueue();
    expect(source.started, ['y:1', 'x:1', 'z:1']);

    source.finish('x:1');
    await pumpEventQueue();
    expect(source.started.last, 'x:m');

    source.finish('z:1');
    source.finish('x:m');
    await run;
  });

  test('Stop abandons running comics and cancels their tokens', () async {
    final run = queue.add(['x:1', 'y:1', 'x:2']);
    await pumpEventQueue();

    queue.cancel();
    await run;

    expect(source.started, ['x:1', 'y:1']);
    expect(source.tokens['x:1']!.cancelled, isTrue);
    expect(source.tokens['y:1']!.cancelled, isTrue);
    expect(notifier.calls.last, 'finish -');

    // A result that still arrives is passed on as late, not counted.
    source.finish(
      'x:1',
      right((
        saved: bookmark('x:1', 'X', 1),
        historyChanged: false,
        failure: null,
      )),
    );
    await pumpEventQueue();
    expect(results, [('x:1', true)]);
  });

  test('a comic over the timeout is skipped; its late result shows', () async {
    queue.dispose();
    queue = make(timeout: const Duration(milliseconds: 20));
    final run = queue.add(['x:1', 'y:1']);
    await pumpEventQueue();
    source.finish('y:1');

    await run;

    expect(source.tokens['x:1']!.cancelled, isTrue);
    expect(results, [('y:1', false)]);
    source.finish('x:1');
    await pumpEventQueue();
    expect(results, [('y:1', false), ('x:1', true)]);
  });

  test(
    'a comic over the timeout keeps its source until its work ends',
    () async {
      queue.dispose();
      queue = make(timeout: const Duration(milliseconds: 20));
      final run = queue.add(['x:1', 'x:2', 'y:1']);
      await pumpEventQueue();
      source.finish('y:1');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await pumpEventQueue();

      // x:1 timed out but still runs: x:2 waits instead of starting.
      expect(source.started, ['x:1', 'y:1']);
      source.finish('x:1');
      await pumpEventQueue();
      expect(source.started.last, 'x:2');
      source.finish('x:2');
      await run;
      expect(results, contains(('x:2', false)));
    },
  );

  test('a stuck comic frees its source after one more timeout', () async {
    queue.dispose();
    queue = make(timeout: const Duration(milliseconds: 20));
    final run = queue.add(['x:1', 'x:2']);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    await pumpEventQueue();

    // x:1 never finishes; x:2 starts once the extra timeout passed.
    expect(source.started, ['x:1', 'x:2']);
    source.finish('x:2');
    await run;
  });

  test('drop forgets queued keys and abandons running ones', () async {
    final run = queue.add(['x:1', 'x:2', 'y:1']);
    await pumpEventQueue();

    queue.drop((key) => key == 'x:1' || key == 'x:2');
    await pumpEventQueue();
    source.finish('y:1');
    await run;

    expect(source.started, ['x:1', 'y:1']);
    expect(source.tokens['x:1']!.cancelled, isTrue);
  });

  test('comics added while the end is reported get their own run', () async {
    final finishing = Completer<void>();
    final slow = _SlowFinish(finishing.future);
    queue.dispose();
    queue = BookmarkRefreshQueue(
      refresh: source.call,
      notifier: slow,
      onResult: (key, result, {required late}) => results.add((key, late)),
    );

    final run = queue.add(['x:1']);
    await pumpEventQueue();
    source.finish('x:1');
    await pumpEventQueue();
    // The run is reporting its end; a pull now must not be lost.
    final joined = queue.add(['y:1']);
    finishing.complete();
    await pumpEventQueue();
    source.finish('y:1');
    await Future.wait([run, joined]);

    expect(source.started, ['x:1', 'y:1']);
    expect(queue.pending, isEmpty);
  });
}

class _SlowFinish extends RecordingNotifier {
  _SlowFinish(this._finishing);

  final Future<void> _finishing;

  @override
  Future<void> finish(int id, {String? title, String? body}) async {
    await super.finish(id, title: title, body: body);
    await _finishing;
  }
}

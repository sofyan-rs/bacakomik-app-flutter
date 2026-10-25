import 'package:bacakomik_app/core/error/exceptions.dart';
import 'package:bacakomik_app/core/source/extension_manager.dart';
import 'package:bacakomik_app/core/source/extension_meta.dart';
import 'package:bacakomik_app/core/source/extension_runtime.dart';

/// A recorded `method(...args)` call on a [FakeSourceBackend].
typedef SourceCall = ({String method, List<Object?> args});

/// Source whose methods return canned JSON. A response may be a value, an
/// [Exception] (thrown) or a function of the call's args.
class FakeSourceBackend implements SourceBackend {
  FakeSourceBackend({
    Map<String, Object?>? responses,
    this.sourceFeatures = const SourceFeatures(),
  }) : responses = responses ?? {};

  final Map<String, Object?> responses;
  SourceFeatures sourceFeatures;
  final calls = <SourceCall>[];

  /// Args of the only call to [method].
  List<Object?> argsOf(String method) =>
      calls.where((c) => c.method == method).single.args;

  @override
  Future<SourceFeatures> features() async => sourceFeatures;

  @override
  Future<Object?> call(String method, List<Object?> args) async {
    calls.add((method: method, args: args));
    if (!responses.containsKey(method)) {
      throw ServerException('No canned response for $method', statusCode: 404);
    }
    final response = responses[method];
    if (response is Exception) throw response;
    if (response is Object? Function(List<Object?>)) return response(args);
    return response;
  }
}

/// Registry serving [FakeSourceBackend]s by source id.
class FakeSourceRegistry implements SourceRegistry {
  FakeSourceRegistry(this.backends, {this.activeSource});

  final Map<String, FakeSourceBackend> backends;
  final requested = <String>[];

  @override
  String? activeSource;

  @override
  Future<SourceBackend> backend(String sourceId) async {
    requested.add(sourceId);
    final backend = backends[sourceId];
    if (backend == null) {
      throw ServerException('Source $sourceId is not installed');
    }
    return backend;
  }
}

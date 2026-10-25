import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

/// Notification ids, one per kind of long-running work.
abstract final class ProgressIds {
  static const bookmarkRefresh = 1;
}

/// A system notification with a progress bar for work the user started,
/// such as refreshing bookmarks.
abstract interface class ProgressNotifier {
  /// Shows or updates the ongoing notification [id]: [done] of [total].
  /// A [cancelable] one has a Cancel button that fires [cancelRequests].
  /// Once the user dismisses it, it stays away until [finish].
  Future<void> progress(
    int id, {
    required String title,
    required int done,
    required int total,
    bool cancelable = false,
  });

  /// Ids of notifications whose Cancel button was tapped.
  Stream<int> get cancelRequests;

  /// Ends [id]: replaced by a dismissible [title] / [body] notification, or
  /// removed when [title] is null.
  Future<void> finish(int id, {String? title, String? body});
}

/// Runs in a background isolate when a notification button that does not
/// open the app is tapped; passes Cancel on to the app's isolate.
@pragma('vm:entry-point')
void progressActionInBackground(NotificationResponse response) {
  if (response.actionId != LocalProgressNotifier.cancelAction) return;
  IsolateNameServer.lookupPortByName(
    LocalProgressNotifier.portName,
  )?.send(response.id);
}

/// Android only; a no-op on other platforms. Asks for the notification
/// permission on first use.
@LazySingleton(as: ProgressNotifier)
class LocalProgressNotifier implements ProgressNotifier {
  static const cancelAction = 'cancel';
  static const portName = 'bacakomik_progress_actions';

  final _plugin = FlutterLocalNotificationsPlugin();
  Future<bool>? _ready;
  final _cancels = StreamController<int>.broadcast();

  /// Ids the user swiped away while they ran.
  final _dismissed = <int>{};

  @override
  Stream<int> get cancelRequests => _cancels.stream;

  /// Calls run one after another, so a late progress update cannot bring
  /// back a finished notification.
  Future<void> _queue = Future.value();

  Future<void> _enqueue(Future<void> Function() call) {
    if (!_supported) return Future.value();
    return _queue = _queue.then((_) async {
      if (await _init()) await call();
    });
  }

  static const _channelId = 'progress';

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> _init() => _ready ??= () async {
    try {
      final port = ReceivePort()
        ..listen((id) {
          if (id is int) _cancels.add(id);
        });
      IsolateNameServer.removePortNameMapping(portName);
      IsolateNameServer.registerPortWithName(port.sendPort, portName);
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(
            '@mipmap/ic_launcher_monochrome',
          ),
        ),
        onDidReceiveNotificationResponse: _onResponse,
        onDidReceiveBackgroundNotificationResponse: progressActionInBackground,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return true;
    } catch (e) {
      debugPrint('ProgressNotifier: $e');
      return false;
    }
  }();

  void _onResponse(NotificationResponse response) {
    final id = response.id;
    if (id == null) return;
    if (response.notificationResponseType ==
        NotificationResponseType.notificationDismissed) {
      _dismissed.add(id);
    } else if (response.actionId == cancelAction) {
      _cancels.add(id);
    }
  }

  @override
  Future<void> progress(
    int id, {
    required String title,
    required int done,
    required int total,
    bool cancelable = false,
  }) => _enqueue(() async {
    if (_dismissed.contains(id)) return;
    await _plugin.show(
      id: id,
      title: title,
      body: '$done / $total',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          AppText.progressChannel,
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          showWhen: false,
          showProgress: true,
          maxProgress: total,
          progress: done,
          dismissIsolate: NotificationDismissedIsolate.main,
          actions: [
            if (cancelable)
              const AndroidNotificationAction(cancelAction, AppText.cancel),
          ],
        ),
      ),
    );
  });

  @override
  Future<void> finish(int id, {String? title, String? body}) =>
      _enqueue(() async {
        _dismissed.remove(id);
        if (title == null) return _plugin.cancel(id: id);
        await _plugin.show(
          id: id,
          title: title,
          body: body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              AppText.progressChannel,
              importance: Importance.low,
              priority: Priority.low,
            ),
          ),
        );
      });
}

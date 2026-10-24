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
  Future<void> progress(
    int id, {
    required String title,
    required int done,
    required int total,
  });

  /// Ends [id]: replaced by a dismissible [title] / [body] notification, or
  /// removed when [title] is null.
  Future<void> finish(int id, {String? title, String? body});
}

/// Android only; a no-op on other platforms. Asks for the notification
/// permission on first use.
@LazySingleton(as: ProgressNotifier)
class LocalProgressNotifier implements ProgressNotifier {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<bool>? _ready;

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
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(
            '@mipmap/ic_launcher_monochrome',
          ),
        ),
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

  @override
  Future<void> progress(
    int id, {
    required String title,
    required int done,
    required int total,
  }) => _enqueue(
    () => _plugin.show(
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
        ),
      ),
    ),
  );

  @override
  Future<void> finish(int id, {String? title, String? body}) =>
      _enqueue(() async {
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

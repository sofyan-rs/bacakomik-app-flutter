import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen on while at least one reader is open and the setting
/// allows it.
///
/// Readers [acquire] in `initState` and [release] in `dispose`. Moving to
/// another chapter replaces the route, so the new reader starts before the
/// old one is disposed; a count, rather than each reader switching the lock
/// itself, keeps the screen on across the change.
class ReaderWakelock {
  ReaderWakelock(this._apply);

  final void Function(bool on) _apply;
  var _holders = 0;
  var _keepOn = false;
  bool? _applied;

  /// The screen is kept on.
  bool get enabled => _holders > 0 && _keepOn;

  @visibleForTesting
  int get holders => _holders;

  void acquire({required bool keepOn}) {
    _holders++;
    _keepOn = keepOn;
    _sync();
  }

  void release() {
    if (_holders > 0) _holders--;
    _sync();
  }

  /// The keep-screen-on setting changed.
  void setKeepOn(bool keepOn) {
    _keepOn = keepOn;
    _sync();
  }

  void _sync() {
    final on = enabled;
    if (on == _applied) return;
    _applied = on;
    _apply(on);
  }
}

/// The app's reader wakelock.
final readerWakelock = ReaderWakelock(
  (on) => on ? WakelockPlus.enable() : WakelockPlus.disable(),
);

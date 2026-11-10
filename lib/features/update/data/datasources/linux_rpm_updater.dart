import 'dart:io';

/// Installs RPM updates with the desktop's administrator authentication prompt.
/// The app stays open until DNF succeeds, so a cancelled prompt is retryable.
class LinuxRpmUpdater {
  LinuxRpmUpdater({
    bool? isLinux,
    Map<String, String>? environment,
    String? executable,
    Future<ProcessResult> Function(String, List<String>)? run,
    Future<void> Function()? restart,
  }) : _isLinux = isLinux ?? Platform.isLinux,
       _environment = environment ?? Platform.environment,
       _executable = executable ?? Platform.resolvedExecutable,
       _run = run ?? Process.run,
       _restart = restart ?? _restartApp;

  final bool _isLinux;
  final Map<String, String> _environment;
  final String _executable;
  final Future<ProcessResult> Function(String, List<String>) _run;
  final Future<void> Function() _restart;
  Future<bool>? _installed;

  /// Query ownership instead of treating every non-AppImage build as an RPM.
  Future<bool> isInstalled() => _installed ??= _detectInstallation();

  Future<bool> _detectInstallation() async {
    if (!_isLinux || (_environment['APPIMAGE']?.isNotEmpty ?? false)) {
      return false;
    }
    try {
      final result = await _run('/usr/bin/rpm', [
        '--query',
        '--file',
        _executable,
        '--queryformat',
        '%{NAME}',
      ]);
      final name = '${result.stdout}'.trim();
      return result.exitCode == 0 && name == 'yoru';
    } on ProcessException {
      // RPM is not available on every Linux distribution.
      return false;
    }
  }

  Future<void> install(File package) async {
    final args = [
      '--disable-internal-agent',
      '/usr/bin/dnf',
      '--assumeyes',
      'install',
      package.absolute.path,
    ];
    final result = await _run('/usr/bin/pkexec', args);
    if (result.exitCode != 0) {
      throw ProcessException(
        '/usr/bin/pkexec',
        args,
        result.exitCode == 126
            ? 'Administrator approval was cancelled'
            : 'RPM installation failed: ${result.stderr}',
        result.exitCode,
      );
    }
  }

  Future<void> restart() => _restart();

  static Future<void> _restartApp() async {
    // Run as the desktop user after the package transaction, never as root.
    await Process.start(
      '/bin/sh',
      [
        '-c',
        r'''
while kill -0 "$YORU_UPDATE_PID" 2>/dev/null; do sleep 0.3; done
exec /usr/bin/yoru
''',
      ],
      environment: {'YORU_UPDATE_PID': '$pid'},
      mode: ProcessStartMode.detached,
    );
    exit(0);
  }
}

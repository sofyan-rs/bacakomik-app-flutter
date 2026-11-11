import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:yoru/core/network/doh.dart';
import 'package:yoru/core/source/mihon_process_host.dart';

/// Applies the DNS over HTTPS setting ('' off, a preset id or a custom URL)
/// to the app's own requests ([Doh]) and to Mihon extensions, whose OkHttp
/// resolves on the Kotlin side (`HostDns`): in the app on Android, in the
/// helper process ([ProcessMihonHost]) on the desktops.
Future<void> applyDnsOverHttps(String setting) async {
  final server = DohServer.fromSetting(setting);
  Doh.use(server);
  if (kIsWeb) return;
  if (!Platform.isAndroid) {
    if (MihonRuntime.platform == null) return;
    return ProcessMihonHost.instance.setDns(
      server?.url,
      server?.bootstrap ?? const <String>[],
    );
  }
  try {
    await const MethodChannel('yoru/mihon').invokeMethod<void>('setDns', {
      'url': server?.url,
      'bootstrap': server?.bootstrap ?? const <String>[],
    });
  } on MissingPluginException {
    // Tests and builds without the Mihon host.
  } on PlatformException catch (e) {
    debugPrint('Mihon DNS not set: $e');
  }
}

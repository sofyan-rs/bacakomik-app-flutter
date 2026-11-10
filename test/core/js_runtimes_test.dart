@TestOn('mac-os')
library;

import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_test/flutter_test.dart';

/// flutter_js on macOS (JavaScriptCore) routes every `sendMessage` through
/// one static callback; it must reach the runtime that sent it, also once a
/// later runtime is disposed (third_party/flutter_js).
void main() {
  test('sendMessage reaches its own runtime with several runtimes', () {
    final received = <String>[];
    final first = getJavascriptRuntime(xhr: false)
      ..onMessage('ch', (args) {
        received.add('first:$args');
        return null;
      });
    final second = getJavascriptRuntime(xhr: false)
      ..onMessage('ch', (args) {
        received.add('second:$args');
        return null;
      });

    first.evaluate('sendMessage("ch", JSON.stringify(1))');
    second.evaluate('sendMessage("ch", JSON.stringify(2))');
    expect(received, ['first:1', 'second:2']);

    // The last runtime made goes away; the first keeps working.
    second.dispose();
    first.evaluate('sendMessage("ch", JSON.stringify(3))');
    expect(received.last, 'first:3');
    first.dispose();
  });
}

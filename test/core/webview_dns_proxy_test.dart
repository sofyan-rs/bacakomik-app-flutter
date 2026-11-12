import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yoru/core/network/webview_dns_proxy.dart';

void main() {
  late HttpServer site;
  late WebViewDnsProxy proxy;
  final asked = <String>[];

  setUp(() async {
    asked.clear();
    site = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    site.listen((request) {
      request.response
        ..write('${request.method} ${request.uri} ${request.headers.host}')
        ..close();
    });
    // Every host resolves to the local site, as DoH would to a real one.
    proxy = await WebViewDnsProxy.start(
      connect: (host, port) {
        asked.add('$host:$port');
        return Socket.connect(InternetAddress.loopbackIPv4, site.port);
      },
    );
  });

  tearDown(() async {
    await proxy.close();
    await site.close(force: true);
  });

  HttpClient client() =>
      HttpClient()..findProxy = (_) => 'PROXY 127.0.0.1:${proxy.port}';

  Future<String> get(HttpClient c, String url) async {
    final response = await (await c.getUrl(Uri.parse(url))).close();
    return response.transform(utf8.decoder).join();
  }

  test('forwards an absolute-form request to the named host', () async {
    final c = client();
    final body = await get(c, 'http://blocked.example/a/b?q=1');
    c.close();
    expect(asked, ['blocked.example:80']);
    expect(body, 'GET /a/b?q=1 blocked.example');
  });

  test('tunnels CONNECT to the named host and port', () async {
    final socket = await Socket.connect(
      InternetAddress.loopbackIPv4,
      proxy.port,
    );
    final lines = <String>[];
    final done = socket
        .cast<List<int>>()
        .transform(latin1.decoder)
        .forEach(lines.add);
    socket.write(
      'CONNECT blocked.example:443 HTTP/1.1\r\nHost: blocked.example\r\n\r\n'
      'GET /x HTTP/1.1\r\nHost: blocked.example\r\nConnection: close\r\n\r\n',
    );
    await done;
    final text = lines.join();
    expect(asked, ['blocked.example:443']);
    expect(text, startsWith('HTTP/1.1 200 Connection Established\r\n\r\n'));
    expect(text, contains('GET /x blocked.example'));
  });

  test('answers 502 when the host cannot be reached', () async {
    await proxy.close();
    proxy = await WebViewDnsProxy.start(
      connect: (_, _) => throw const SocketException('no address'),
    );
    final c = client();
    final response = await (await c.getUrl(
      Uri.parse('http://nowhere.example/'),
    )).close();
    c.close();
    expect(response.statusCode, 502);
  });

  test('answers while listening', () async {
    expect(await proxy.answers(), isTrue);
    await proxy.close();
    expect(await proxy.answers(), isFalse);
  });
}

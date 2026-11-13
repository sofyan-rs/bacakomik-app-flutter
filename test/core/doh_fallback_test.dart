import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoru/core/network/doh.dart';
import 'package:yoru/core/source/extension_bridge.dart';

/// Records what it was sent; fails with [error] when given.
class _Adapter implements HttpClientAdapter {
  _Adapter({this.error});

  final Object? error;
  final bodies = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    bodies.add(
      requestStream == null
          ? null
          : utf8.decode(await requestStream.expand((c) => c).toList()),
    );
    if (error != null) throw error!;
    return ResponseBody.fromString('ok', 200);
  }

  @override
  void close({bool force = false}) {}
}

const _blocked =
    'NetworkException: Exception in CronetUrlRequest: '
    'net::ERR_CERT_AUTHORITY_INVALID, ErrorCode=11';

void main() {
  tearDown(() {
    Doh.use(null);
    DohFallback.reset();
  });

  group('DohFallback', () {
    test('takes nothing while DoH is off', () {
      expect(DohFallback.takes('comix.to', _blocked), isFalse);
      expect(DohFallback.skipsNative('comix.to'), isFalse);
    });

    test('takes Cronet failures while DoH is on and remembers the host', () {
      Doh.use(dohPresets.first);
      expect(DohFallback.takes('comix.to', 'HTTP 403'), isFalse);
      expect(DohFallback.skipsNative('comix.to'), isFalse);
      expect(DohFallback.takes('comix.to', _blocked), isTrue);
      expect(DohFallback.skipsNative('comix.to'), isTrue);
      expect(DohFallback.skipsNative('other.site'), isFalse);
    });

    test('forgets the hosts when DoH goes off', () {
      Doh.use(dohPresets.first);
      DohFallback.takes('comix.to', _blocked);
      Doh.use(null);
      expect(DohFallback.skipsNative('comix.to'), isFalse);
    });
  });

  group('DohFallbackAdapter', () {
    Future<void> post(DohFallbackAdapter adapter) async {
      final dio = Dio()..httpClientAdapter = adapter;
      await dio.post<String>('https://comix.to/api', data: 'body');
    }

    test(
      'sends a blocked request again through dart:io, body and all',
      () async {
        Doh.use(dohPresets.first);
        final native = _Adapter(error: Exception(_blocked));
        final io = _Adapter();
        await post(DohFallbackAdapter(native, io));
        expect(native.bodies, ['body']);
        expect(io.bodies, ['body']);

        // The host skips Cronet from now on.
        await post(DohFallbackAdapter(native, io));
        expect(native.bodies, hasLength(1));
        expect(io.bodies, hasLength(2));
      },
    );

    test('keeps the failure while DoH is off', () async {
      final native = _Adapter(error: Exception(_blocked));
      final io = _Adapter();
      await expectLater(
        post(DohFallbackAdapter(native, io)),
        throwsA(isA<DioException>()),
      );
      expect(io.bodies, isEmpty);
    });

    test('keeps failures that are not Cronet reaching the host', () async {
      Doh.use(dohPresets.first);
      final native = _Adapter(error: Exception('something else'));
      final io = _Adapter();
      await expectLater(
        post(DohFallbackAdapter(native, io)),
        throwsA(isA<DioException>()),
      );
      expect(io.bodies, isEmpty);
    });
  });
}

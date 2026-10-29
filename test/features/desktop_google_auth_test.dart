import 'dart:convert';

import 'package:bacakomik_app/features/sync/data/datasources/desktop_google_auth_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/hive.dart';

void main() {
  late Future<void> Function() tearDownHive;
  late Box<String> box;

  setUp(() async {
    tearDownHive = await setUpTempHive();
    box = await Hive.openBox<String>('sync');
  });

  tearDown(() => tearDownHive());

  Future<void> signedIn() => box.put(
    'desktop_google',
    jsonEncode({'email': 'a@b.c', 'refresh_token': 'refresh'}),
  );

  test('restores the stored account without the network', () async {
    final auth = DesktopGoogleAuthDataSource(
      box,
      client: MockClient((_) async => fail('no request expected')),
    );
    expect(await auth.restore(), isNull);
    await signedIn();
    expect(await auth.restore(), 'a@b.c');
  });

  test('refreshes the access token once and reuses it', () async {
    await signedIn();
    final requests = <http.Request>[];
    final auth = DesktopGoogleAuthDataSource(
      box,
      client: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({'access_token': 'token1', 'expires_in': 3600}),
          200,
        );
      }),
    );
    expect(await auth.accessToken(), 'token1');
    expect(await auth.accessToken(), 'token1');
    expect(requests, hasLength(1));
    expect(requests.single.bodyFields['grant_type'], 'refresh_token');
    expect(requests.single.bodyFields['refresh_token'], 'refresh');

    // A token the server rejected is fetched again.
    await auth.clearAccessToken('token1');
    await auth.accessToken();
    expect(requests, hasLength(2));
  });

  test('forgets the account when Google revoked the grant', () async {
    await signedIn();
    final auth = DesktopGoogleAuthDataSource(
      box,
      client: MockClient(
        (_) async => http.Response(jsonEncode({'error': 'invalid_grant'}), 400),
      ),
    );
    expect(await auth.accessToken(), isNull);
    expect(await auth.restore(), isNull);
  });

  test('sign-out revokes the refresh token and forgets it', () async {
    await signedIn();
    final requests = <http.Request>[];
    final auth = DesktopGoogleAuthDataSource(
      box,
      client: MockClient((request) async {
        requests.add(request);
        return http.Response('', 200);
      }),
    );
    await auth.signOut();
    expect(requests.single.url.path, '/revoke');
    expect(requests.single.bodyFields['token'], 'refresh');
    expect(await auth.restore(), isNull);
    expect(await auth.accessToken(), isNull);
  });
}

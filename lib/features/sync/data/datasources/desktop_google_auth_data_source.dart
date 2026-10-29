import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:bacakomik_app/features/sync/data/datasources/google_auth_data_source.dart';
import 'package:crypto/crypto.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Google sign-in on desktop, where `google_sign_in` has no implementation:
/// OAuth in the browser with a loopback redirect and PKCE, as Google
/// documents for installed apps. The refresh token is kept in [_box].
class DesktopGoogleAuthDataSource implements GoogleAuthDataSource {
  DesktopGoogleAuthDataSource(this._box, {http.Client? client})
    : _http = client ?? http.Client();

  final Box<String> _box;
  final http.Client _http;

  static const _key = 'desktop_google';
  static const _authUrl = 'https://accounts.google.com/o/oauth2/v2/auth';
  static const _tokenUrl = 'https://oauth2.googleapis.com/token';
  static const _revokeUrl = 'https://oauth2.googleapis.com/revoke';

  /// How long the browser has to come back before sign-in counts as
  /// cancelled.
  static const _timeout = Duration(minutes: 3);

  String? _accessToken;
  DateTime? _expires;

  ({String email, String refreshToken})? get _stored {
    final raw = _box.get(_key);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (
      email: json['email'] as String,
      refreshToken: json['refresh_token'] as String,
    );
  }

  @override
  Future<String?> restore() async => _stored?.email;

  @override
  Future<String?> signIn() async {
    if (AppVariables.googleDesktopClientId.isEmpty) {
      throw StateError('No Google desktop client id in this build');
    }
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    try {
      final redirect = 'http://127.0.0.1:${server.port}';
      final verifier = _random(64);
      final state = _random(24);
      final challenge = base64Url
          .encode(sha256.convert(ascii.encode(verifier)).bytes)
          .replaceAll('=', '');
      final url = Uri.parse(_authUrl).replace(
        queryParameters: {
          'client_id': AppVariables.googleDesktopClientId,
          'redirect_uri': redirect,
          'response_type': 'code',
          'scope': [
            'openid',
            'email',
            ...GoogleAuthDataSourceImpl.scopes,
          ].join(' '),
          'code_challenge': challenge,
          'code_challenge_method': 'S256',
          'state': state,
          'access_type': 'offline',
          // A refresh token comes only with the consent screen.
          'prompt': 'consent',
        },
      );
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw StateError('Could not open the browser');
      }

      final code = await _awaitCode(
        server,
        state,
      ).timeout(_timeout, onTimeout: () => null);
      if (code == null) return null;

      final token = await _token({
        'code': code,
        'code_verifier': verifier,
        'grant_type': 'authorization_code',
        'redirect_uri': redirect,
      });
      final refreshToken = token['refresh_token'] as String?;
      final email = _emailOf(token['id_token'] as String?);
      if (refreshToken == null || email == null) {
        throw StateError('Google returned no refresh token or email');
      }
      await _box.put(
        _key,
        jsonEncode({'email': email, 'refresh_token': refreshToken}),
      );
      _keep(token);
      return email;
    } finally {
      await server.close(force: true);
    }
  }

  /// The code from the browser's redirect, or null when the user refused.
  Future<String?> _awaitCode(HttpServer server, String state) async {
    await for (final request in server) {
      final params = request.uri.queryParameters;
      // Favicon and other stray requests.
      if (!params.containsKey('code') && !params.containsKey('error')) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        continue;
      }
      final ok = params['state'] == state && params['code'] != null;
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write(
          '<!doctype html><meta charset="utf-8"><title>BacaKomik</title>'
          '<body style="font-family:sans-serif;text-align:center;'
          'padding-top:20vh">'
          '<h2>${ok ? 'Signed in' : 'Sign-in cancelled'}</h2>'
          '<p>You can close this tab and go back to BacaKomik.</p>',
        );
      await request.response.close();
      return ok ? params['code'] : null;
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    final stored = _stored;
    _accessToken = null;
    _expires = null;
    await _box.delete(_key);
    if (stored == null) return;
    try {
      await _http.post(
        Uri.parse(_revokeUrl),
        body: {'token': stored.refreshToken},
      );
    } catch (_) {
      // Signed out here either way; the grant lapses unused.
    }
  }

  @override
  Future<String?> accessToken() async {
    final stored = _stored;
    if (stored == null) return null;
    final expires = _expires;
    if (_accessToken != null &&
        expires != null &&
        DateTime.now().isBefore(expires)) {
      return _accessToken;
    }
    try {
      _keep(
        await _token({
          'refresh_token': stored.refreshToken,
          'grant_type': 'refresh_token',
        }),
      );
    } on _GrantRevoked {
      await _box.delete(_key);
      return null;
    }
    return _accessToken;
  }

  @override
  Future<void> clearAccessToken(String token) async {
    if (token != _accessToken) return;
    _accessToken = null;
    _expires = null;
  }

  void _keep(Map<String, dynamic> token) {
    _accessToken = token['access_token'] as String?;
    final seconds = (token['expires_in'] as num?)?.toInt() ?? 0;
    // A minute early, so a token never runs out mid-request.
    _expires = DateTime.now().add(Duration(seconds: max(0, seconds - 60)));
  }

  Future<Map<String, dynamic>> _token(Map<String, String> body) async {
    final response = await _http.post(
      Uri.parse(_tokenUrl),
      body: {
        ...body,
        'client_id': AppVariables.googleDesktopClientId,
        'client_secret': AppVariables.googleDesktopClientSecret,
      },
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) return json;
    if (json['error'] == 'invalid_grant') throw const _GrantRevoked();
    throw HttpException(
      'Google token request failed (${response.statusCode}): '
      '${json['error_description'] ?? json['error']}',
    );
  }

  /// The email claim of a Google ID token. Not verified: it came straight
  /// from Google's token endpoint over TLS.
  static String? _emailOf(String? idToken) {
    final parts = idToken?.split('.');
    if (parts == null || parts.length != 3) return null;
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    return (jsonDecode(payload) as Map<String, dynamic>)['email'] as String?;
  }

  static String _random(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}

/// The user revoked the app's access, or the refresh token expired.
class _GrantRevoked implements Exception {
  const _GrantRevoked();
}

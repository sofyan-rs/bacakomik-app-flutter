import 'package:bacakomik_app/core/constants/variables.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

/// Google sign-in limited to the app's private Drive folder.
abstract interface class GoogleAuthDataSource {
  /// Email of the account signed in on an earlier run, without any prompt.
  Future<String?> restore();

  /// Null when the user cancelled.
  Future<String?> signIn();

  Future<void> signOut();

  /// Null when signed out or Drive access was revoked.
  Future<String?> accessToken();

  /// Forgets a token the server rejected so the next [accessToken] call
  /// fetches a fresh one.
  Future<void> clearAccessToken(String token);
}

@LazySingleton(as: GoogleAuthDataSource)
class GoogleAuthDataSourceImpl implements GoogleAuthDataSource {
  static const scopes = ['https://www.googleapis.com/auth/drive.appdata'];

  final _google = GoogleSignIn.instance;
  Future<void>? _initialized;
  GoogleSignInAccount? _account;

  Future<void> _init() => _initialized ??= _google.initialize(
    serverClientId: AppVariables.googleServerClientId,
  );

  @override
  Future<String?> restore() async {
    await _init();
    _account = await _google.attemptLightweightAuthentication();
    return _account?.email;
  }

  @override
  Future<String?> signIn() async {
    await _init();
    try {
      final account = await _google.authenticate(scopeHint: scopes);
      await account.authorizationClient.authorizeScopes(scopes);
      _account = account;
      return account.email;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _init();
    await _google.signOut();
    _account = null;
  }

  @override
  Future<String?> accessToken() async {
    final authorization = await _account?.authorizationClient
        .authorizationForScopes(scopes);
    return authorization?.accessToken;
  }

  @override
  Future<void> clearAccessToken(String token) async {
    await _init();
    await _google.authorizationClient.clearAuthorizationToken(
      accessToken: token,
    );
  }
}

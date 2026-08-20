import 'package:flutter/foundation.dart';
import 'package:taxi_app/core/network/token_service.dart';

// Bridges auth-state changes (token expiry, logout) to GoRouter.
// Router listens via [tick] and re-runs its `redirect:` callback,
// which reads token presence from [StorageRepository].
class AuthSession {
  // Bumped whenever token/refresh is added or cleared.
  // Use as `refreshListenable:` on GoRouter.
  static final ValueNotifier<int> tick = ValueNotifier<int>(0);

  // Which backend issued the token currently in `'token'`.
  // Written by whichever data source persisted the session, read by the
  // izzydrive dio interceptor so it can tell a genuinely expired izzydrive
  // token from a toll token that api.izzydrive.com was never going to accept.
  static const String _sourceKey = 'session_source';
  static const String sourceAuth1 = 'auth1';
  static const String sourceAuth2 = 'auth2';

  static String get source => StorageRepository.getString(_sourceKey);

  // True when the stored session came from the Quadrix toll backend, i.e.
  // there is no `'refresh'` to spend and izzydrive will always reject it.
  static bool get isTollSession => source == sourceAuth2;

  static Future<void> setSource(String value) async {
    await StorageRepository.putString(_sourceKey, value);
  }

  static bool get isLoggedIn =>
      StorageRepository.getString('token').isNotEmpty;

  static bool get isPhoneVerified =>
      StorageRepository.getBool('phone_verified');

  // Call after the dio interceptor (or auth bloc) clears tokens. Triggers
  // router redirect: any non-auth route bounces to signIn.
  static Future<void> clear() async {
    await StorageRepository.deleteString('token');
    await StorageRepository.deleteString('refresh');
    await StorageRepository.deleteString('responseID');
    await StorageRepository.deleteString(_sourceKey);
    await StorageRepository.deleteBool('phone_verified');
    tick.value++;
  }

  // Call after a successful login/refresh persists new tokens, so the
  // router re-evaluates and lets the user into protected routes.
  static void notifyAuthChanged() {
    tick.value++;
  }
}

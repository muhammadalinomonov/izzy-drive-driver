import 'package:flutter/foundation.dart';
import 'package:taxi_app/core/network/token_service.dart';

// Bridges auth-state changes (token expiry, logout) to GoRouter.
// Router listens via [tick] and re-runs its `redirect:` callback,
// which reads token presence from [StorageRepository].
class AuthSession {
  // Bumped whenever token/refresh is added or cleared.
  // Use as `refreshListenable:` on GoRouter.
  static final ValueNotifier<int> tick = ValueNotifier<int>(0);

  static bool get isLoggedIn =>
      StorageRepository.getString('token').isNotEmpty;

  static bool get isPhoneVerified =>
      StorageRepository.getBool('phone_verified');

  // Call after the dio interceptor (or auth bloc) clears tokens. Triggers
  // router redirect: any non-auth route bounces to signIn.
  static Future<void> clear() async {
    await StorageRepository.deleteString('token');
    await StorageRepository.deleteString('refresh');
    await StorageRepository.deleteBool('phone_verified');
    tick.value++;
  }

  // Call after a successful login/refresh persists new tokens, so the
  // router re-evaluates and lets the user into protected routes.
  static void notifyAuthChanged() {
    tick.value++;
  }
}

import 'package:flutter/foundation.dart';
import 'package:taxi_app/core/network/token_service.dart';

/// App-wide premium entitlement, sourced from the driver profile's
/// `is_paid_user` flag.
///
/// Follows the same static-holder shape as `TollSession`, which is how this
/// project already carries cross-feature session state - no GetIt registration
/// (DI here is per-route by design, see CLAUDE.md) and no bloc, because
/// premium is read from widely-scattered places that have no business
/// depending on the profile feature's bloc.
///
/// Two ways to consume it:
/// - [isPremium] for one-off checks in callbacks and guards.
/// - [listenable] with a `ValueListenableBuilder` for UI that must appear or
///   disappear the moment the flag resolves, such as the premium-only Support
///   Message button.
///
/// The value is persisted so a cold start does not briefly downgrade a paying
/// driver to the free experience while the profile request is in flight.
class PremiumSession {
  PremiumSession._();

  static const String _key = 'is_paid_user';

  static final ValueNotifier<bool> _notifier =
      ValueNotifier<bool>(StorageRepository.getBool(_key));

  /// True when the driver is a Premium user.
  static bool get isPremium => _notifier.value;

  /// Rebuilds dependents when the entitlement changes.
  static ValueListenable<bool> get listenable => _notifier;

  /// Records the flag from a freshly-loaded profile.
  ///
  /// Safe to call on every profile load: the notifier only fires when the
  /// value actually changes, so repeated refreshes don't churn the widget
  /// tree.
  static Future<void> update(bool value) async {
    if (_notifier.value == value && StorageRepository.getBool(_key) == value) {
      return;
    }
    _notifier.value = value;
    await StorageRepository.putBool(key: _key, value: value);
  }

  /// Drops the entitlement. Call on sign-out so the next account does not
  /// inherit the previous driver's premium features.
  static Future<void> clear() async {
    _notifier.value = false;
    await StorageRepository.deleteBool(_key);
  }
}

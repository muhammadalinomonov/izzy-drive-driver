import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Thin wrapper over Firebase Remote Config for feature flags.
///
/// Defaults are intentionally SAFE (features OFF): if the fetch fails, times
/// out, or hasn't completed yet, the app behaves as the most conservative,
/// review-safe version. Flip a flag to `true` in the Firebase console only once
/// the gated feature is complete and compliant.
class RemoteConfigService {
  RemoteConfigService._();

  /// Console parameter key. Create it in Firebase Console → Remote Config with
  /// a Boolean value (keep it `false` for App Review; set `true` to roll out).
  static const String kShowOtherOpportunities = 'show_other_opportunities';

  static bool _showOtherOpportunities = false;

  /// Whether the home "Other opportunities" section should be shown.
  static bool get showOtherOpportunities => _showOtherOpportunities;

  static Future<void> init() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await rc.setDefaults(const {kShowOtherOpportunities: false});
      await rc.fetchAndActivate();
      _showOtherOpportunities = rc.getBool(kShowOtherOpportunities);
    } catch (_) {
      // Any failure -> keep the safe default (section hidden).
      _showOtherOpportunities = false;
    }
  }
}

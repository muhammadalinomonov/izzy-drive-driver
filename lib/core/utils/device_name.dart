import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Human-readable label for this device.
///
/// Exists for `device_name` on `POST mobile/auth/login`
/// (`docs/mobile-api.md` §2.1): the Quadrix backend names the Sanctum token
/// after it, so it is what a driver sees when reviewing which devices are
/// signed in — "Alex iPhone", not a uuid.
///
/// Never throws and never returns empty: the field is required, so a device
/// that withholds its name still has to send something.
class DeviceName {
  DeviceName._();

  static const String _fallback = 'Mobile device';

  /// Cached because the platform channel round-trip is pure overhead on a
  /// value that cannot change while the app is running.
  static String? _cached;

  static Future<String> resolve() async {
    final cached = _cached;
    if (cached != null) return cached;
    return _cached = await _read();
  }

  static Future<String> _read() async {
    final info = DeviceInfoPlugin();
    try {
      if (Platform.isIOS) {
        final ios = await info.iosInfo;
        // From iOS 16 `name` is the model ("iPhone") rather than the user's
        // chosen name unless the app holds the entitlement — still a usable
        // label, so only a genuinely empty one falls through to the machine id.
        final name = ios.name.trim();
        return name.isNotEmpty ? name : ios.utsname.machine;
      }
      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        final label = '${android.manufacturer} ${android.model}'.trim();
        return label.isNotEmpty ? label : _fallback;
      }
    } catch (_) {
      // Plugin missing (tests) or channel failure — the login must not die
      // over a cosmetic field.
    }
    return _fallback;
  }
}

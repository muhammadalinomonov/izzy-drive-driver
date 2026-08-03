import 'package:flutter/material.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';

/// Compact pill-shaped speedometer for Driving Mode.
///
/// Ported from the Quadrix driver app's `presentation/widgets/speedometer.dart`
/// with one deliberate change: it reads **mph**, not km/h. This app is imperial
/// end to end — the API field is `speed_mph`, and every distance on this screen
/// is in miles — so a km/h readout would be the only metric figure on the map.
///
/// Stateless by design: the caller passes a fresh value on each GPS update, so
/// the widget holds no timers and nothing to dispose.
class Speedometer extends StatelessWidget {
  /// Raw speed in metres per second, as reported by the GPS stream. Null
  /// before the first fix arrives.
  final double? speedMps;

  const Speedometer({super.key, required this.speedMps});

  static const double _mphPerMps = 2.23694;

  @override
  Widget build(BuildContext context) {
    final speed = speedMps;
    // A negative or NaN speed means "unknown" from the platform, not "stopped",
    // but 0 is the honest thing to show either way - the vehicle is not moving
    // in any way we can evidence.
    final display =
        (speed != null && speed.isFinite && speed > 0) ? (speed * _mphPerMps).round() : 0;

    return Material(
      color: AppColor.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$display',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColor.black,
                letterSpacing: -0.4,
                // height: 1 so the number's baseline sits flush with the unit
                // label beside it instead of floating on default line spacing.
                height: 1,
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                'mph',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColor.grey,
                  letterSpacing: -0.2,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

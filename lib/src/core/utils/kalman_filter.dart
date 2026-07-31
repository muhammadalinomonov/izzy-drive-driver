import 'dart:math' as math;

import 'package:taxi_app/src/core/utils/polyline_codec.dart';

/// 2-D Kalman filter that smooths a stream of GPS fixes.
///
/// Receivers typically jitter +/-3-10 m around the true position, so feeding
/// raw fixes to the driver marker makes it dance even while parked. This keeps
/// a running position estimate plus a variance, and blends each new reading in
/// with a gain derived from the fix's reported accuracy.
///
/// Ported unchanged in behaviour from the Quadrix driver app's
/// `feature/maps/data/kalman_filter.dart`.
///
/// Tuning:
/// - [processNoiseMps] - assumed motion between fixes. Higher trusts the raw
///   measurement more (snappier marker, less smoothing). 3 m/s suits city
///   driving with ~1 Hz updates.
/// - [minAccuracyM] - floor on the accuracy value, guarding against platforms
///   reporting 0 or a negative.
class KalmanFilter {
  final double processNoiseMps;
  final double minAccuracyM;

  double? _lat;
  double? _lng;

  /// Uncertainty of the current estimate in m^2. `-1` until the first fix.
  double _variance = -1;
  DateTime? _lastTime;

  KalmanFilter({this.processNoiseMps = 3.0, this.minAccuracyM = 1.0});

  bool get isInitialized => _variance >= 0;

  /// Filters one GPS sample and returns the smoothed position to draw.
  ///
  /// The first sample seeds the filter and is returned unchanged. Later
  /// samples are blended with a gain that grows with the time elapsed since
  /// the previous fix and shrinks as [accuracyM] improves.
  LatLng filter({
    required LatLng measurement,
    required double accuracyM,
    required DateTime time,
    required double speedMps,
  }) {
    final acc =
        (accuracyM.isNaN || accuracyM < minAccuracyM) ? minAccuracyM : accuracyM;
    final measurementVariance = acc * acc;

    if (!isInitialized) {
      _lat = measurement.latitude;
      _lng = measurement.longitude;
      _variance = measurementVariance;
      _lastTime = time;
      return measurement;
    }

    // Predict: the estimate decays in confidence as time passes without a
    // measurement. Bound the motion by the reported speed or the process
    // noise, whichever is larger.
    final dt = time.difference(_lastTime!).inMilliseconds / 1000.0;
    if (dt > 0) {
      final noise = math.max(speedMps, processNoiseMps);
      _variance += dt * noise * noise;
    }
    _lastTime = time;

    // Update: the Kalman gain is the estimate's share of the total
    // uncertainty. High gain => trust the incoming measurement.
    final k = _variance / (_variance + measurementVariance);
    _lat = _lat! + k * (measurement.latitude - _lat!);
    _lng = _lng! + k * (measurement.longitude - _lng!);
    _variance = (1 - k) * _variance;

    return LatLng(_lat!, _lng!);
  }

  void reset() {
    _lat = null;
    _lng = null;
    _variance = -1;
    _lastTime = null;
  }
}

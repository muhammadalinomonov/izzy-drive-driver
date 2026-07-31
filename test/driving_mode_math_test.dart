import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_app/src/core/utils/geo_math.dart';
import 'package:taxi_app/src/core/utils/kalman_filter.dart';
import 'package:taxi_app/src/core/utils/polyline_codec.dart';
import 'package:taxi_app/src/core/utils/route_progress.dart';
import 'package:taxi_app/src/features/trips/presentation/controllers/marker_animator.dart';

/// Covers the pure layer ported from the Quadrix driver app. Everything here
/// is Flutter-free maths, so it can be asserted exactly rather than eyeballed
/// on a moving map.
void main() {
  group('haversine', () {
    test('one degree of latitude is ~111.2 km', () {
      final d = haversine(const LatLng(0, 0), const LatLng(1, 0));
      expect(d, closeTo(111195, 50));
    });

    test('is symmetric and zero for identical points', () {
      const a = LatLng(40.7128, -74.0060);
      const b = LatLng(34.0522, -118.2437);
      expect(haversine(a, b), closeTo(haversine(b, a), 0.001));
      expect(haversine(a, a), closeTo(0, 0.001));
    });

    test('NYC to LA is ~3936 km', () {
      final d = haversine(
        const LatLng(40.7128, -74.0060),
        const LatLng(34.0522, -118.2437),
      );
      expect(d / 1000, closeTo(3936, 10));
    });
  });

  group('bearingBetween', () {
    test('due north is 0 and due east is 90', () {
      expect(bearingBetween(const LatLng(0, 0), const LatLng(1, 0)),
          closeTo(0, 0.01));
      expect(bearingBetween(const LatLng(0, 0), const LatLng(0, 1)),
          closeTo(90, 0.01));
    });

    test('due south is 180 and due west is 270', () {
      expect(bearingBetween(const LatLng(1, 0), const LatLng(0, 0)),
          closeTo(180, 0.01));
      expect(bearingBetween(const LatLng(0, 1), const LatLng(0, 0)),
          closeTo(270, 0.01));
    });
  });

  group('bearingDelta', () {
    test('wraps across the 0/360 seam by the short way', () {
      expect(bearingDelta(10, 350), closeTo(20, 0.001));
      expect(bearingDelta(350, 10), closeTo(-20, 0.001));
    });

    test('stays within (-180, 180]', () {
      for (var a = 0.0; a < 360; a += 17) {
        for (var b = 0.0; b < 360; b += 23) {
          final d = bearingDelta(a, b);
          expect(d, greaterThan(-180.0001));
          expect(d, lessThanOrEqualTo(180.0001));
        }
      }
    });
  });

  group('MarkerAnimator.interpolateBearing', () {
    test('takes the short arc across the seam', () {
      // 350 -> 10 must pass through 0, not sweep back through 180.
      expect(MarkerAnimator.interpolateBearing(350, 10, 0.5), closeTo(0, 0.001));
    });

    test('endpoints are exact', () {
      expect(MarkerAnimator.interpolateBearing(30, 200, 0), closeTo(30, 0.001));
      expect(
          MarkerAnimator.interpolateBearing(30, 200, 1), closeTo(200, 0.001));
    });

    test('always returns a normalised bearing', () {
      for (var t = 0.0; t <= 1.0; t += 0.05) {
        final b = MarkerAnimator.interpolateBearing(350, 10, t);
        expect(b, greaterThanOrEqualTo(0));
        expect(b, lessThan(360));
      }
    });
  });

  group('segmentT', () {
    const a = LatLng(0, 0);
    const b = LatLng(0, 1);

    test('is 0 at the start, 1 at the end, 0.5 at the midpoint', () {
      expect(segmentT(a, a, b), closeTo(0, 0.001));
      expect(segmentT(b, a, b), closeTo(1, 0.001));
      expect(segmentT(const LatLng(0, 0.5), a, b), closeTo(0.5, 0.001));
    });

    test('goes negative behind the segment and past 1 beyond it', () {
      expect(segmentT(const LatLng(0, -0.2), a, b), lessThan(0));
      expect(segmentT(const LatLng(0, 1.2), a, b), greaterThan(1));
    });

    test('returns 0 for a degenerate segment', () {
      expect(segmentT(const LatLng(1, 1), a, a), 0);
    });
  });

  group('forwardTarget', () {
    test('100 m north raises latitude by ~0.0009 degrees', () {
      final p = forwardTarget(const LatLng(40, -74), 0, 100);
      expect(p.latitude - 40, closeTo(0.000899, 0.00002));
      expect(p.longitude, closeTo(-74, 0.00001));
    });

    test('the offset distance round-trips through haversine', () {
      const origin = LatLng(40, -74);
      for (final bearing in [0.0, 45.0, 137.0, 250.0, 359.0]) {
        final p = forwardTarget(origin, bearing, 250);
        expect(haversine(origin, p), closeTo(250, 0.5));
        expect(bearingBetween(origin, p), closeTo(bearing, 0.1));
      }
    });
  });

  group('interpolateRoute', () {
    test('keeps every segment under the step length', () {
      final dense = interpolateRoute(
        const [LatLng(0, 0), LatLng(0, 0.01)],
        stepMeters: 50,
      );
      for (var i = 0; i < dense.length - 1; i++) {
        expect(haversine(dense[i], dense[i + 1]), lessThanOrEqualTo(50.001));
      }
    });

    test('preserves the endpoints', () {
      const input = [LatLng(0, 0), LatLng(0, 0.01), LatLng(0.01, 0.01)];
      final dense = interpolateRoute(input);
      expect(dense.first.latitude, input.first.latitude);
      expect(dense.first.longitude, input.first.longitude);
      expect(dense.last.latitude, input.last.latitude);
      expect(dense.last.longitude, input.last.longitude);
    });

    test('passes through degenerate input untouched', () {
      expect(interpolateRoute(const []), isEmpty);
      expect(interpolateRoute(const [LatLng(1, 1)]).length, 1);
    });
  });

  group('CumulativeDistances', () {
    test('fromStart and toEnd are complementary', () {
      const points = [LatLng(0, 0), LatLng(0, 0.01), LatLng(0, 0.02)];
      final cum = CumulativeDistances.fromPoints(points);

      expect(cum.fromStart.first, 0);
      expect(cum.toEnd.last, 0);
      expect(cum.fromStart.last, closeTo(cum.total, 0.001));
      for (var i = 0; i < points.length; i++) {
        expect(cum.fromStart[i] + cum.toEnd[i], closeTo(cum.total, 0.001));
      }
    });

    test('handles an empty route', () {
      final cum = CumulativeDistances.fromPoints(const []);
      expect(cum.total, 0);
      expect(cum.fromStart, isEmpty);
    });
  });

  group('snapToRoute', () {
    // A straight run east along the equator, ~1.1 km per 0.01 degrees.
    const points = [LatLng(0, 0), LatLng(0, 0.01), LatLng(0, 0.02)];
    final cum = CumulativeDistances.fromPoints(points);

    test('projects a point beside the line onto its perpendicular foot', () {
      // 0.001 degrees north of the line at the midpoint of segment 0.
      final progress = snapToRoute(const LatLng(0.001, 0.005), points, cum);

      expect(progress, isNotNull);
      expect(progress!.segmentIndex, 0);
      expect(progress.segmentT, closeTo(0.5, 0.01));
      expect(progress.splitPoint.latitude, closeTo(0, 0.0001));
      expect(progress.splitPoint.longitude, closeTo(0.005, 0.0001));
    });

    test('travelled and remaining sum to the route total', () {
      final progress = snapToRoute(const LatLng(0.0005, 0.013), points, cum);
      expect(progress, isNotNull);
      expect(
        progress!.travelledMeters + progress.remainingMeters,
        closeTo(cum.total, 1),
      );
      expect(progress.segmentIndex, 1);
    });

    test('advances monotonically as the driver moves along the route', () {
      double previous = -1;
      for (var lng = 0.0; lng <= 0.02; lng += 0.002) {
        final progress = snapToRoute(LatLng(0, lng), points, cum);
        expect(progress, isNotNull);
        expect(progress!.travelledMeters, greaterThanOrEqualTo(previous));
        previous = progress.travelledMeters;
      }
    });

    test('returns null for a degenerate polyline', () {
      expect(
        snapToRoute(const LatLng(0, 0), const [LatLng(0, 0)],
            CumulativeDistances.fromPoints(const [LatLng(0, 0)])),
        isNull,
      );
    });
  });

  group('KalmanFilter', () {
    test('returns the first sample unchanged', () {
      final filter = KalmanFilter();
      const measurement = LatLng(40.7128, -74.0060);
      final out = filter.filter(
        measurement: measurement,
        accuracyM: 5,
        time: DateTime(2026, 1, 1),
        speedMps: 0,
      );

      expect(out.latitude, measurement.latitude);
      expect(out.longitude, measurement.longitude);
      expect(filter.isInitialized, isTrue);
    });

    test('smooths a noisy stationary signal toward the truth', () {
      final filter = KalmanFilter();
      const truth = LatLng(40.0, -74.0);
      final random = math.Random(42);
      var time = DateTime(2026, 1, 1);

      LatLng out = truth;
      for (var i = 0; i < 60; i++) {
        // +/- ~0.00005 degrees is roughly +/- 5 m of jitter.
        final noisy = LatLng(
          truth.latitude + (random.nextDouble() - 0.5) * 0.0001,
          truth.longitude + (random.nextDouble() - 0.5) * 0.0001,
        );
        time = time.add(const Duration(seconds: 1));
        out = filter.filter(
          measurement: noisy,
          accuracyM: 5,
          time: time,
          speedMps: 0,
        );
      }

      // The smoothed estimate must land closer to the truth than the raw
      // jitter amplitude (~5 m).
      expect(haversine(out, truth), lessThan(5));
    });

    test('reset clears the estimate', () {
      final filter = KalmanFilter();
      filter.filter(
        measurement: const LatLng(1, 1),
        accuracyM: 5,
        time: DateTime(2026, 1, 1),
        speedMps: 0,
      );
      expect(filter.isInitialized, isTrue);

      filter.reset();
      expect(filter.isInitialized, isFalse);

      // After a reset the next sample is again passed through untouched.
      const next = LatLng(2, 2);
      final out = filter.filter(
        measurement: next,
        accuracyM: 5,
        time: DateTime(2026, 1, 1),
        speedMps: 0,
      );
      expect(out.latitude, next.latitude);
    });

    test('a bad accuracy report is floored, not trusted', () {
      final filter = KalmanFilter();
      final time = DateTime(2026, 1, 1);
      filter.filter(
        measurement: const LatLng(40, -74),
        accuracyM: 0,
        time: time,
        speedMps: 0,
      );
      // A zero-accuracy claim must not divide by zero or produce NaN.
      final out = filter.filter(
        measurement: const LatLng(40.0001, -74),
        accuracyM: -1,
        time: time.add(const Duration(seconds: 1)),
        speedMps: 0,
      );
      expect(out.latitude.isFinite, isTrue);
      expect(out.longitude.isFinite, isTrue);
    });
  });
}

import 'dart:math' as math;

import 'package:taxi_app/src/core/utils/polyline_codec.dart';

/// Pure spherical-geometry helpers for Driving Mode.
///
/// Deliberately free of any map-SDK import: these operate on the plain
/// [LatLng] from `polyline_codec.dart`, so the same functions serve the
/// Mapbox layer, the driving controllers, and unit tests without dragging a
/// platform view into scope.
///
/// Ported from the Quadrix driver app's `feature/maps/domain/geo_math.dart`,
/// retyped off `google_maps_flutter`'s LatLng.

const double _earthRadiusM = 6371000;

/// Great-circle distance between two coordinates in metres (Haversine).
double haversine(LatLng a, LatLng b) {
  final lat1 = _radians(a.latitude);
  final lat2 = _radians(b.latitude);
  final dLat = lat2 - lat1;
  final dLon = _radians(b.longitude - a.longitude);

  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
  final c = 2 * math.asin(math.min(1.0, math.sqrt(h)));
  return _earthRadiusM * c;
}

/// Initial bearing from [a] to [b] in degrees, normalised to `[0, 360)`.
double bearingBetween(LatLng a, LatLng b) {
  final lat1 = _radians(a.latitude);
  final lat2 = _radians(b.latitude);
  final dLon = _radians(b.longitude - a.longitude);
  final y = math.sin(dLon) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
  return (_degrees(math.atan2(y, x)) + 360) % 360;
}

/// Closest point on segment `a-b` to [p], using a local equirectangular
/// projection. Accurate enough for sub-kilometre segments (route polyline
/// waypoints) and far cheaper than a full geodesic projection.
LatLng projectOnSegment(LatLng p, LatLng a, LatLng b) {
  final t = segmentT(p, a, b).clamp(0.0, 1.0);
  return LatLng(
    a.latitude + (b.latitude - a.latitude) * t,
    a.longitude + (b.longitude - a.longitude) * t,
  );
}

/// Unclamped projection parameter of [p] onto segment `a-b` in local
/// equirectangular space. `t < 0` means [p] sits behind [a]; `t > 1` means it
/// is past [b]. Used to walk backward to the segment the marker is on without
/// rescanning the whole route.
double segmentT(LatLng p, LatLng a, LatLng b) {
  const metersPerDegLat = 111320.0;
  final metersPerDegLng =
      metersPerDegLat * math.cos(_radians((a.latitude + b.latitude) / 2));

  final dx = (b.longitude - a.longitude) * metersPerDegLng;
  final dy = (b.latitude - a.latitude) * metersPerDegLat;
  final segLen2 = dx * dx + dy * dy;
  if (segLen2 == 0) return 0;

  final px = (p.longitude - a.longitude) * metersPerDegLng;
  final py = (p.latitude - a.latitude) * metersPerDegLat;
  return (px * dx + py * dy) / segLen2;
}

/// The point reached by travelling [meters] from [origin] along [bearingDeg].
/// Drives the driving camera's look-ahead target.
LatLng forwardTarget(LatLng origin, double bearingDeg, double meters) {
  final brng = _radians(bearingDeg);
  final lat1 = _radians(origin.latitude);
  final lon1 = _radians(origin.longitude);
  final angDist = meters / _earthRadiusM;

  final lat2 = math.asin(
    math.sin(lat1) * math.cos(angDist) +
        math.cos(lat1) * math.sin(angDist) * math.cos(brng),
  );
  final lon2 = lon1 +
      math.atan2(
        math.sin(brng) * math.sin(angDist) * math.cos(lat1),
        math.cos(angDist) - math.sin(lat1) * math.sin(lat2),
      );

  return LatLng(_degrees(lat2), ((_degrees(lon2) + 540) % 360) - 180);
}

/// Densifies [points] so no consecutive segment exceeds [stepMeters].
///
/// The navigation API returns route geometry with sparse vertices on long
/// straights. Snapping and marker path-following both behave better on an
/// evenly sampled line, so the decoded polyline is run through this once when
/// a session's route is installed.
List<LatLng> interpolateRoute(List<LatLng> points, {double stepMeters = 50}) {
  if (points.length < 2) return List.of(points);
  final result = <LatLng>[];
  for (int i = 0; i < points.length - 1; i++) {
    final a = points[i];
    final b = points[i + 1];
    result.add(a);
    // ceil, not floor: with floor, a 99 m gap at a 50 m step yields steps = 1,
    // the loop below never runs, and the segment survives at 99 m - twice the
    // length this function promises. (The Quadrix original floors here; the
    // densified line it produces is coarser than its own doc claims.)
    final steps = (haversine(a, b) / stepMeters).ceil();
    for (int j = 1; j < steps; j++) {
      final t = j / steps;
      result.add(LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      ));
    }
  }
  result.add(points.last);
  return result;
}

/// Smallest signed difference between two bearings, in `(-180, 180]`.
double bearingDelta(double a, double b) {
  var delta = (a - b) % 360;
  if (delta > 180) delta -= 360;
  if (delta < -180) delta += 360;
  return delta;
}

double _radians(double deg) => deg * math.pi / 180;
double _degrees(double rad) => rad * 180 / math.pi;

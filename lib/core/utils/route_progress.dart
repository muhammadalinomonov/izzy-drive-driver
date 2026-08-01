import 'package:taxi_app/core/utils/geo_math.dart';
import 'package:taxi_app/core/utils/polyline_codec.dart';

/// Pre-computed cumulative distances along a route polyline.
///
/// Built once per route (on session start, reroute, or alternative swap) so a
/// GPS fix can answer "how far have I come / how much is left" without
/// re-summing the whole line every second.
///
/// Ported from the Quadrix driver app's `feature/maps/domain/route_progress.dart`.
class CumulativeDistances {
  /// `fromStart[i]` = metres from `points[0]` to `points[i]`. Always starts 0.
  final List<double> fromStart;

  /// `toEnd[i]` = metres from `points[i]` to `points.last`. Always ends 0.
  final List<double> toEnd;

  /// Total route length in metres.
  double get total => toEnd.isEmpty ? 0 : toEnd.first;

  const CumulativeDistances({required this.fromStart, required this.toEnd});

  factory CumulativeDistances.fromPoints(List<LatLng> points) {
    if (points.isEmpty) {
      return const CumulativeDistances(fromStart: [], toEnd: []);
    }

    final n = points.length;
    final fromStart = List<double>.filled(n, 0);
    for (int i = 1; i < n; i++) {
      fromStart[i] = fromStart[i - 1] + haversine(points[i - 1], points[i]);
    }
    final total = fromStart.last;
    final toEnd = List<double>.generate(n, (i) => total - fromStart[i]);

    return CumulativeDistances(fromStart: fromStart, toEnd: toEnd);
  }
}

/// Where the driver sits on the planned line, derived from a raw fix plus the
/// cached cumulative distances.
typedef RouteProgress = ({
  /// Segment the driver is on (`points[i] -> points[i+1]`).
  int segmentIndex,

  /// Position within that segment, `[0, 1]`.
  double segmentT,

  /// Metres already travelled along the planned line.
  double travelledMeters,

  /// Metres remaining to the route's end.
  double remainingMeters,

  /// Closest point on the polyline to the driver. Doubles as the marker's
  /// snapped display position and as the driven/remaining split point.
  LatLng splitPoint,
});

/// Projects [position] onto [points] and returns the resulting progress.
/// Null when the polyline is empty or degenerate.
RouteProgress? snapToRoute(
  LatLng position,
  List<LatLng> points,
  CumulativeDistances cumulative,
) {
  if (points.length < 2) return null;
  if (cumulative.fromStart.length != points.length) return null;

  int bestIdx = 0;
  double bestT = 0;
  LatLng bestPoint = points[0];
  double bestDist = double.infinity;

  for (int i = 0; i < points.length - 1; i++) {
    final a = points[i];
    final b = points[i + 1];
    final projected = projectOnSegment(position, a, b);
    final dist = haversine(position, projected);
    if (dist < bestDist) {
      bestDist = dist;
      bestIdx = i;
      bestPoint = projected;
      final segLen = haversine(a, b);
      bestT =
          segLen == 0 ? 0 : (haversine(a, projected) / segLen).clamp(0.0, 1.0);
    }
  }

  final segLen = haversine(points[bestIdx], points[bestIdx + 1]);
  final travelled = cumulative.fromStart[bestIdx] + segLen * bestT;
  final remaining =
      (cumulative.total - travelled).clamp(0, cumulative.total).toDouble();

  return (
    segmentIndex: bestIdx,
    segmentT: bestT,
    travelledMeters: travelled,
    remainingMeters: remaining,
    splitPoint: bestPoint,
  );
}

// A `splitAt` helper returning the two half-routes used to live here. It was
// dropped because splitting per GPS fix is both too slow and too coarse: it
// copied the whole route twice a second, and the boundary only moved at fix
// rate while the marker glided at 60 fps, so the seam visibly jumped. The
// driving page now splits at the animated marker position each frame, holding
// the bulk of the line in two static polylines and rebuilding only the two
// short connectors that meet at the vehicle.

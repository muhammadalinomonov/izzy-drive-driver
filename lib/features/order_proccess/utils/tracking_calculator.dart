import 'dart:math';

double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _rad(double deg) => deg * pi / 180;

// Average city driving speed used as a fallback when the backend hasn't
// provided distance/duration on the route - 30 km/h ≈ 0.5 km/min.
const double _fallbackSpeedKmPerMin = 0.5;

int etaMinutes(
  double mechLat,
  double mechLng,
  double destLat,
  double destLng,
  double totalDurationMin,
  double totalDistanceKm,
) {
  final remaining = haversineKm(mechLat, mechLng, destLat, destLng);
  if (remaining <= 0) return 0;

  // If we have both totalDistance and totalDuration, derive speed from them.
  if (totalDistanceKm > 0 && totalDurationMin > 0) {
    final speed = totalDistanceKm / totalDurationMin; // km/min
    return (remaining / speed).ceil();
  }

  return (remaining / _fallbackSpeedKmPerMin).ceil();
}

String etaLabel(int etaMin) {
  if (etaMin <= 0) return '< 1 min';
  return '~$etaMin min';
}

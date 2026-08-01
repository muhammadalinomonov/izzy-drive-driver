/// Distance and duration formatting for the trips feature.
///
/// The toll API reports distances in metres and durations in seconds, but the
/// network it prices is US-only — every driver-facing figure is miles. These
/// helpers were duplicated across five widgets in three files before being
/// lifted here; keep new call sites pointed at them so the rounding rules
/// can't drift apart again.
library;

const double metersPerMile = 1609.344;

double metersToMiles(num meters) => meters / metersPerMile;

/// `0.4 mi`, `12.3 mi`, `120 mi`.
///
/// The decimal is dropped at or above [wholeAbove]: a long-haul total doesn't
/// need tenth-of-a-mile precision, but a turn coming up in 0.3 mi does. The
/// default suits trip totals and remaining-distance readouts; the maneuver
/// banner passes a much lower threshold.
String formatMiles(num meters, {double wholeAbove = 100}) {
  final miles = metersToMiles(meters);
  return '${miles.toStringAsFixed(miles >= wholeAbove ? 0 : 1)} mi';
}

/// `45m`, `2h`, `2h 15m` — zero components are dropped rather than padded.
String formatDuration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  if (hours == 0) return '${minutes}m';
  return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
}

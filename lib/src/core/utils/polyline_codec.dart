/// Decoder for Google's encoded-polyline algorithm format, precision 5.
///
/// The toll API returns every route alternative's `polyline` in this format
/// (`polyline_format: "encoded_polyline"`, docs/mobile-api.md §4). No pubspec
/// dependency pulled in for this - the algorithm is short and stable.
library;

/// A decoded polyline point, in `(latitude, longitude)` order.
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}

List<LatLng> decodePolyline(String encoded, {int precision = 5}) {
  if (encoded.isEmpty) return const [];

  final factor = _pow10(precision);
  final points = <LatLng>[];
  int index = 0;
  int lat = 0;
  int lng = 0;

  int nextValue() {
    int shift = 0;
    int result = 0;
    int b;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    return (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
  }

  while (index < encoded.length) {
    lat += nextValue();
    lng += nextValue();
    points.add(LatLng(lat / factor, lng / factor));
  }

  return points;
}

double _pow10(int exponent) {
  double result = 1.0;
  for (var i = 0; i < exponent; i++) {
    result *= 10;
  }
  return result;
}

import 'dart:math' as math;

import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/core/utils/geo_math.dart';
import 'package:taxi_app/core/utils/polyline_codec.dart';
import 'package:taxi_app/features/trips/data/model/fuel_station_model.dart';
import 'package:taxi_app/features/trips/data/model/trip_model.dart';

/// PLACEHOLDER nearby-fuel-stations source.
///
/// The backend endpoint does not exist yet. This generates plausible stations
/// around the driver so the whole feature - UI, selection, routing, states -
/// can be built and exercised now.
///
/// ## Replacing this with the real API
///
/// Everything above this class is already API-shaped: [FuelStationModel]
/// parses the JSON the endpoint is expected to return, and the repository
/// returns `NetworkResponse` exactly like every other source here. When the
/// endpoint lands, swap the body of [getNearbyFuelStations] for a real call:
///
/// ```dart
/// final response = await client.get(
///   TollApiConstants.fuelStations,
///   queryParameters: {
///     'lat': currentLocation.lat,
///     'lng': currentLocation.lng,
///     'radius_meters': radiusMeters,
///   },
/// );
/// ```
///
/// Nothing in the bloc or the UI should need to change.
class FuelStationsDataSource {
  /// Simulated latency, so loading states are actually exercised in
  /// development rather than resolving in the same frame.
  static const Duration _fakeLatency = Duration(milliseconds: 600);

  /// Deterministic per-location seed: panning back to the same place shows
  /// the same stations instead of reshuffling on every request.
  int _seedFor(TripCoordinate origin) {
    return ((origin.lat * 1000).round() * 31 + (origin.lng * 1000).round())
        .abs();
  }

  Future<NetworkResponse<List<FuelStationModel>>> getNearbyFuelStations({
    required TripCoordinate currentLocation,
    required double radiusMeters,
  }) async {
    await Future.delayed(_fakeLatency);

    try {
      final random = math.Random(_seedFor(currentLocation));
      final origin = LatLng(currentLocation.lat, currentLocation.lng);
      final count = 6 + random.nextInt(4); // 6-9 stations

      final stations = <FuelStationModel>[];
      for (var i = 0; i < count; i++) {
        // Spread them across the full bearing range, biased outward via sqrt
        // so they don't clump at the centre the way a uniform radius does.
        final bearing = random.nextDouble() * 360;
        final distance = radiusMeters * math.sqrt(random.nextDouble());
        final point = forwardTarget(origin, bearing, distance);

        final brand = _brands[random.nextInt(_brands.length)];
        final priceMin = 45000 + random.nextInt(1500) * 10;
        final priceMax = priceMin + random.nextInt(800) * 10;

        stations.add(
          FuelStationModel(
            id: 'placeholder-fuel-$i-${_seedFor(currentLocation)}',
            name: '$brand ${_suffixes[random.nextInt(_suffixes.length)]}',
            brand: brand,
            address: '${100 + random.nextInt(8900)} '
                '${_streets[random.nextInt(_streets.length)]}',
            coordinate: TripCoordinate(
              lat: point.latitude,
              lng: point.longitude,
            ),
            distanceMeters: distance.round(),
            priceMinMinor: priceMin,
            priceMaxMinor: priceMax,
            currency: 'USD',
          ),
        );
      }

      // Nearest first, which is the order the list and the map both want.
      stations.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      return NetworkResponse<List<FuelStationModel>>(data: stations);
    } catch (e) {
      return NetworkResponse<List<FuelStationModel>>(errorText: e.toString());
    }
  }

  static const List<String> _brands = [
    'Alixon Fuel',
    'Pilot',
    'Love\'s',
    'TA Travel',
    'Shell',
    'Chevron',
  ];

  static const List<String> _suffixes = [
    'Travel Center',
    'Truck Stop',
    'Station',
    'Fuel Plaza',
  ];

  static const List<String> _streets = [
    'Kuhn Rd, West Memphis, AR',
    'Interstate Dr, Memphis, TN',
    'Airways Blvd, Memphis, TN',
    'Getwell Rd, Southaven, MS',
    'Lamar Ave, Memphis, TN',
  ];
}

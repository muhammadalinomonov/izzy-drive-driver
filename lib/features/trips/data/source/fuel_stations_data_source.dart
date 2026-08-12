import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:taxi_app/core/extensions/status_code_extension.dart';
import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/core/network/toll_api_constants.dart';
import 'package:taxi_app/core/network/toll_dio.dart';
import 'package:taxi_app/core/network/toll_session.dart';
import 'package:taxi_app/core/service_locater.dart';
import 'package:taxi_app/core/utils/geo_math.dart';
import 'package:taxi_app/core/utils/json_safe.dart';
import 'package:taxi_app/core/utils/polyline_codec.dart';
import 'package:taxi_app/features/trips/data/model/fuel_station_model.dart';
import 'package:taxi_app/features/trips/data/model/trip_model.dart';

/// `GET mobile/fuel-stations` — the EFS fuel-station catalogue (docs §7.1).
///
/// Two shape mismatches between what the screen wants ("stations near me") and
/// what the endpoint offers are resolved here rather than in the bloc:
///
/// 1. **No centre+radius query.** The catalogue filters by bounding box only,
///    so the requested radius is converted into a lat/lng box and the corners
///    are sent together - the filter is ignored unless all four are present.
/// 2. **No distance field.** A box query returns no distance, so each station
///    is measured against the driver's position locally and the corner-cut
///    results outside the radius are dropped, leaving a true circular search.
@lazySingleton
class FuelStationsDataSource {
  FuelStationsDataSource();

  final client = serviceLocator.get<TollDioSettings>().dio;

  /// Catalogue maximum (docs §7.1). Asked for in full: the box is small, the
  /// results are drawn as map markers, and paging through a 20-item default
  /// would spend several of the 60 req/min budget per pan.
  static const int _perPage = 100;

  Future<NetworkResponse<List<FuelStationModel>>> getNearbyFuelStations({
    required TripCoordinate currentLocation,
    required double radiusMeters,
  }) async {
    if (!TollSession.hasToken) {
      return NetworkResponse<List<FuelStationModel>>(
        errorText: 'Toll account is not connected.',
        errorCode: 'TOLL_SESSION_MISSING',
      );
    }
    try {
      final bounds = _boundsAround(currentLocation, radiusMeters);
      final response = await client.get(
        TollApiConstants.fuelStations,
        queryParameters: {
          'north': bounds.north,
          'south': bounds.south,
          'east': bounds.east,
          'west': bounds.west,
          'per_page': _perPage,
        },
      );
      if (response.isSuccess) {
        final data = toMap(toMap(response.data)['data']);
        final stations = toList(
          data['items'],
          (e) => FuelStationModel.fromJson(toMap(e)),
        );
        return NetworkResponse<List<FuelStationModel>>(
          data: _withinRadius(stations, currentLocation, radiusMeters),
        );
      }
      return NetworkResponse<List<FuelStationModel>>(
        errorText: _errorMessage(response.data),
        errorCode: _errorCode(response.data),
      );
    } on DioException catch (e) {
      return NetworkResponse<List<FuelStationModel>>(
        errorText: _errorMessage(e.response?.data, 'Network error'),
        errorCode: _errorCode(e.response?.data),
      );
    } catch (e) {
      return NetworkResponse<List<FuelStationModel>>(errorText: e.toString());
    }
  }

  /// Measures every station against the driver, drops the ones the bounding
  /// box's corners let in beyond [radiusMeters], and sorts nearest first -
  /// the order both the markers and any list want.
  List<FuelStationModel> _withinRadius(
    List<FuelStationModel> stations,
    TripCoordinate origin,
    double radiusMeters,
  ) {
    final from = LatLng(origin.lat, origin.lng);
    final measured = <FuelStationModel>[];
    for (final station in stations) {
      final metres = haversine(
        from,
        LatLng(station.coordinate.lat, station.coordinate.lng),
      );
      if (metres > radiusMeters) continue;
      measured.add(station.withDistance(metres.round()));
    }
    measured.sort((a, b) => (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0));
    return measured;
  }

  /// The smallest lat/lng box containing every point within [radiusMeters] of
  /// [centre].
  ///
  /// Latitude is a fixed 111.32 km per degree; longitude shrinks with the
  /// cosine of the latitude, so the two spans are computed separately. Values
  /// are clamped to the endpoint's own `-90..90` / `-180..180` limits, since
  /// anything outside them answers 422 VALIDATION_FAILED.
  _Bounds _boundsAround(TripCoordinate centre, double radiusMeters) {
    const metresPerDegLat = 111320.0;
    final latSpan = radiusMeters / metresPerDegLat;
    final cosLat = math.cos(centre.lat * math.pi / 180).abs();
    // Near the poles cosLat collapses toward zero; floor it so the division
    // cannot blow the longitude span up past the whole globe.
    final lngSpan = radiusMeters / (metresPerDegLat * math.max(cosLat, 0.01));

    return _Bounds(
      north: (centre.lat + latSpan).clamp(-90.0, 90.0),
      south: (centre.lat - latSpan).clamp(-90.0, 90.0),
      east: (centre.lng + lngSpan).clamp(-180.0, 180.0),
      west: (centre.lng - lngSpan).clamp(-180.0, 180.0),
    );
  }

  /// Same nested-`error` envelope the rest of the toll API uses.
  static String _errorMessage(dynamic body, [String fallback = 'Server error']) {
    if (body is Map) {
      final error = body['error'];
      if (error is Map) {
        final message = error['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    }
    return dioErrorMessage(body, fallback);
  }

  static String? _errorCode(dynamic body) {
    if (body is! Map) return null;
    final error = body['error'];
    if (error is! Map) return null;
    final code = error['code'];
    return code is String && code.isNotEmpty ? code : null;
  }
}

class _Bounds {
  final double north;
  final double south;
  final double east;
  final double west;

  const _Bounds({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });
}

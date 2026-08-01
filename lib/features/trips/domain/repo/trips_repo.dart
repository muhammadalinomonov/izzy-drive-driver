import 'package:dio/dio.dart';
import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/trips/data/model/navigation_session_model.dart';
import 'package:taxi_app/features/trips/data/model/place_model.dart';
import 'package:taxi_app/features/trips/data/model/trip_model.dart';
import 'package:taxi_app/features/trips/data/model/vehicle_model.dart';

abstract class TripsRepo {
  Future<NetworkResponse<TripPage>> fetchPage({
    int page,
    int perPage,
    String? status,
  });

  Future<NetworkResponse<List<PlaceModel>>> searchPlaces(
    String query, {
    CancelToken? cancelToken,
  });

  Future<NetworkResponse<TripModel>> fetchById(String routeRequestId);

  Future<NetworkResponse<TripModel>> createRoute({
    required TripCoordinate origin,
    required TripCoordinate destination,
    DateTime? departureAt,
    List<TripCoordinate>? waypoints,
  });

  Future<NetworkResponse<NavigationSessionModel>> createNavigationSession({
    required String routeRequestId,
    required String routeAlternativeId,
    TripCoordinate? currentLocation,
  });

  Future<NetworkResponse<NavigationSessionModel?>> getCurrentNavigationSession();

  Future<NetworkResponse<NavigationSessionModel>> sendNavigationLocation(
    String navigationSessionId, {
    required DateTime occurredAt,
    required double latitude,
    required double longitude,
    double? speedMph,
    double? headingDegrees,
    double? accuracyMeters,
  });

  Future<NetworkResponse<NavigationSessionModel>> rerouteNavigationSession(
    String navigationSessionId, {
    TripCoordinate? currentLocation,
  });

  Future<NetworkResponse<NavigationSessionModel>> completeNavigationSession(
    String navigationSessionId,
  );

  Future<NetworkResponse<NavigationSessionModel>> cancelNavigationSession(
    String navigationSessionId,
  );

  /// Trucks assigned to the driver. Needed to learn the `vehicle_id` that
  /// background fleet GPS requires.
  Future<NetworkResponse<List<VehicleModel>>> fetchVehicles();

  /// Background fleet GPS (docs §6.1) — records the truck's position
  /// independently of navigation progress.
  Future<NetworkResponse<bool>> sendFleetLocation({
    required String vehicleId,
    required DateTime occurredAt,
    required double latitude,
    required double longitude,
    double? speedMph,
    double? headingDegrees,
    double? accuracyMeters,
  });
}

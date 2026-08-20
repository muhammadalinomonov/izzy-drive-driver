import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';
import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/trips/data/model/navigation_session_model.dart';
import 'package:taxi_app/features/trips/data/model/place_model.dart';
import 'package:taxi_app/features/trips/data/model/trip_model.dart';
import 'package:taxi_app/features/trips/data/model/vehicle_model.dart';
import 'package:taxi_app/features/trips/data/source/trips_data_source.dart';
import 'package:taxi_app/features/trips/domain/repo/trips_repo.dart';

@LazySingleton(as: TripsRepo)
class TripsRepoImpl extends TripsRepo {
  final TripsDataSource dataSource;

  TripsRepoImpl({required this.dataSource});

  @override
  Future<NetworkResponse<TripPage>> fetchPage({
    int page = 1,
    int perPage = 20,
    String? status,
  }) {
    return dataSource.fetchPage(page: page, perPage: perPage, status: status);
  }

  @override
  Future<NetworkResponse<List<PlaceModel>>> searchPlaces(
    String query, {
    CancelToken? cancelToken,
  }) {
    return dataSource.searchPlaces(query, cancelToken: cancelToken);
  }

  @override
  Future<NetworkResponse<TripModel>> fetchById(String routeRequestId) {
    return dataSource.fetchById(routeRequestId);
  }

  @override
  Future<NetworkResponse<TripModel>> createRoute({
    required TripCoordinate origin,
    required TripCoordinate destination,
    DateTime? departureAt,
    List<TripCoordinate>? waypoints,
  }) {
    return dataSource.createRoute(
      origin: origin,
      destination: destination,
      departureAt: departureAt,
      waypoints: waypoints,
    );
  }

  @override
  Future<NetworkResponse<NavigationSessionModel>> createNavigationSession({
    required String routeRequestId,
    required String routeAlternativeId,
    TripCoordinate? currentLocation,
    String? routeReviewId,
  }) {
    return dataSource.createNavigationSession(
      routeRequestId: routeRequestId,
      routeAlternativeId: routeAlternativeId,
      currentLocation: currentLocation,
      routeReviewId: routeReviewId,
    );
  }

  @override
  Future<NetworkResponse<NavigationSessionModel?>> getCurrentNavigationSession() {
    return dataSource.getCurrentNavigationSession();
  }

  @override
  Future<NetworkResponse<NavigationSessionModel>> sendNavigationLocation(
    String navigationSessionId, {
    required DateTime occurredAt,
    required double latitude,
    required double longitude,
    double? speedMph,
    double? headingDegrees,
    double? accuracyMeters,
  }) {
    return dataSource.sendNavigationLocation(
      navigationSessionId,
      occurredAt: occurredAt,
      latitude: latitude,
      longitude: longitude,
      speedMph: speedMph,
      headingDegrees: headingDegrees,
      accuracyMeters: accuracyMeters,
    );
  }

  @override
  Future<NetworkResponse<NavigationSessionModel>> rerouteNavigationSession(
    String navigationSessionId, {
    TripCoordinate? currentLocation,
  }) {
    return dataSource.rerouteNavigationSession(
      navigationSessionId,
      currentLocation: currentLocation,
    );
  }

  @override
  Future<NetworkResponse<NavigationSessionModel>> completeNavigationSession(
    String navigationSessionId,
  ) {
    return dataSource.completeNavigationSession(navigationSessionId);
  }

  @override
  Future<NetworkResponse<NavigationSessionModel>> cancelNavigationSession(
    String navigationSessionId,
  ) {
    return dataSource.cancelNavigationSession(navigationSessionId);
  }

  @override
  Future<NetworkResponse<List<VehicleModel>>> fetchVehicles() {
    return dataSource.fetchVehicles();
  }

  @override
  Future<NetworkResponse<bool>> sendFleetLocation({
    required String vehicleId,
    required DateTime occurredAt,
    required double latitude,
    required double longitude,
    double? speedMph,
    double? headingDegrees,
    double? accuracyMeters,
  }) {
    return dataSource.sendFleetLocation(
      vehicleId: vehicleId,
      occurredAt: occurredAt,
      latitude: latitude,
      longitude: longitude,
      speedMph: speedMph,
      headingDegrees: headingDegrees,
      accuracyMeters: accuracyMeters,
    );
  }
}

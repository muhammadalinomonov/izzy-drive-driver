import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/features/trips/data/model/navigation_session_model.dart';
import 'package:taxi_app/src/features/trips/data/model/place_model.dart';
import 'package:taxi_app/src/features/trips/data/model/trip_model.dart';

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
}

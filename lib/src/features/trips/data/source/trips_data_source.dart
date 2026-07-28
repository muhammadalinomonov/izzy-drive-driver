import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/extensions/status_code_extension.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/core/network/toll_api_constants.dart';
import 'package:taxi_app/src/core/network/toll_dio.dart';
import 'package:taxi_app/src/core/network/toll_session.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/core/utils/json_safe.dart';
import 'package:taxi_app/src/features/trips/data/model/navigation_session_model.dart';
import 'package:taxi_app/src/features/trips/data/model/place_model.dart';
import 'package:taxi_app/src/features/trips/data/model/trip_model.dart';

class TripsDataSource {
  TripsDataSource();

  final client = serviceLocator.get<TollDioSettings>().dio;

  /// `GET mobile/toll-routes` — the driver's own paginated toll-route history.
  Future<NetworkResponse<TripPage>> fetchPage({
    int page = 1,
    int perPage = 20,
    String? status,
  }) async {
    // Without a Sanctum token every call is a guaranteed 401. Fail fast with
    // an actionable message rather than surfacing a raw auth error. (The org
    // id needs no check - TollDioSettings resolves it from the token.)
    if (!TollSession.hasToken) {
      return NetworkResponse<TripPage>(
        errorText: 'Toll account is not connected.',
        errorCode: 'TOLL_SESSION_MISSING',
      );
    }
    try {
      final response = await client.get(
        TollApiConstants.tollRoutes,
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      if (response.isSuccess) {
        return NetworkResponse<TripPage>(
          data: TripPage.fromJson(toMap(response.data)),
        );
      }
      return NetworkResponse<TripPage>(
        errorText: _errorMessage(response.data),
        errorCode: _errorCode(response.data),
      );
    } on DioException catch (e) {
      return NetworkResponse<TripPage>(
        errorText: _errorMessage(e.response?.data, 'Network error'),
        errorCode: _errorCode(e.response?.data),
      );
    } catch (e) {
      return NetworkResponse<TripPage>(errorText: e.toString());
    }
  }

  /// Shortest `q` the backend accepts - anything less answers
  /// 422 VALIDATION_FAILED ("The q field must be at least 3 characters."),
  /// verified against the live API.
  static const int minQueryLength = 3;

  /// `GET mobile/places` - server-side geocoding for route endpoints.
  ///
  /// [cancelToken] lets the caller abort a still-flying request when newer
  /// input arrives; a cancelled call reports `errorCode: REQUEST_CANCELLED`
  /// so the bloc can ignore it rather than render it as a failure.
  Future<NetworkResponse<List<PlaceModel>>> searchPlaces(
    String query, {
    CancelToken? cancelToken,
  }) async {
    if (!TollSession.hasToken) {
      return NetworkResponse<List<PlaceModel>>(
        errorText: 'Toll account is not connected.',
        errorCode: 'TOLL_SESSION_MISSING',
      );
    }
    final trimmed = query.trim();
    if (trimmed.length < minQueryLength) {
      // Don't spend a round-trip on input the backend will reject anyway.
      return NetworkResponse<List<PlaceModel>>(
        errorText: 'Query too short.',
        errorCode: 'QUERY_TOO_SHORT',
      );
    }
    try {
      final response = await client.get(
        TollApiConstants.places,
        queryParameters: {'q': trimmed},
        cancelToken: cancelToken,
      );
      if (response.isSuccess) {
        final data = toMap(toMap(response.data)['data']);
        return NetworkResponse<List<PlaceModel>>(
          data: toList(data['items'], (e) => PlaceModel.fromJson(toMap(e))),
        );
      }
      return NetworkResponse<List<PlaceModel>>(
        errorText: _errorMessage(response.data),
        errorCode: _errorCode(response.data),
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return NetworkResponse<List<PlaceModel>>(
          errorText: 'cancelled',
          errorCode: 'REQUEST_CANCELLED',
        );
      }
      return NetworkResponse<List<PlaceModel>>(
        errorText: _errorMessage(e.response?.data, 'Network error'),
        errorCode: _errorCode(e.response?.data),
      );
    } catch (e) {
      return NetworkResponse<List<PlaceModel>>(errorText: e.toString());
    }
  }

  /// `POST mobile/toll-routes` — prices a trip and returns every route
  /// alternative (toll, fuel, time) for the driver's currently-assigned
  /// truck. The response is the same `RouteRequest` shape as [fetchPage]'s
  /// items, so it's parsed with the same [TripModel].
  Future<NetworkResponse<TripModel>> createRoute({
    required TripCoordinate origin,
    required TripCoordinate destination,
    DateTime? departureAt,
    List<TripCoordinate>? waypoints,
  }) async {
    if (!TollSession.hasToken) {
      return NetworkResponse<TripModel>(
        errorText: 'Toll account is not connected.',
        errorCode: 'TOLL_SESSION_MISSING',
      );
    }
    try {
      // Computed once and reused across retries below - the endpoint uses it
      // to de-dupe resubmits of the exact same request, so a fresh key per
      // attempt would defeat that guarantee (and could double-price a trip).
      final idempotencyKey =
          'mobile-route-${DateTime.now().millisecondsSinceEpoch}';
      final response = await _postWithRetry(
        TollApiConstants.tollRoutes,
        data: {
          'origin': {'lat': origin.lat, 'lng': origin.lng},
          'destination': {'lat': destination.lat, 'lng': destination.lng},
          // Despite docs/mobile-api.md marking this optional, the live
          // backend answers 422 VALIDATION_FAILED ("departure_at field is
          // required") without it - confirmed against the running API, so a
          // default of "now" is always sent rather than trusting the doc.
          'departure_at': (departureAt ?? DateTime.now()).toUtc().toIso8601String(),
          if (waypoints != null && waypoints.isNotEmpty)
            'waypoints': waypoints.map((w) => {'lat': w.lat, 'lng': w.lng}).toList(),
        },
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
      );
      if (response.isSuccess) {
        return NetworkResponse<TripModel>(
          data: TripModel.fromJson(toMap(toMap(response.data)['data'])),
        );
      }
      return NetworkResponse<TripModel>(
        errorText: _errorMessage(response.data),
        errorCode: _errorCode(response.data),
      );
    } on DioException catch (e) {
      return NetworkResponse<TripModel>(
        errorText: _errorMessage(e.response?.data, 'Network error'),
        errorCode: _errorCode(e.response?.data),
      );
    } catch (e) {
      return NetworkResponse<TripModel>(errorText: e.toString());
    }
  }

  /// 502/503/504 and connection-level failures are transient (the toll API
  /// is fronted by Cloudflare, which answers 502 whenever its origin is
  /// briefly overloaded) - worth a couple of quick retries before surfacing
  /// an error to the driver. Anything else (4xx, validation errors, auth
  /// failures) is not retried and propagates immediately.
  static const _retryableStatusCodes = {502, 503, 504};

  Future<Response> _postWithRetry(
    String path, {
    required Map<String, dynamic> data,
    required Options options,
    int maxAttempts = 3,
  }) async {
    for (var attempt = 1;; attempt++) {
      try {
        return await client.post(path, data: data, options: options);
      } on DioException catch (e) {
        final retryable = _retryableStatusCodes.contains(e.response?.statusCode) ||
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout;
        if (!retryable || attempt >= maxAttempts) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }

  /// `POST mobile/navigation-sessions` — starts (or, per the API doc,
  /// re-issues) guidance for a chosen route alternative.
  Future<NetworkResponse<NavigationSessionModel>> createNavigationSession({
    required String routeRequestId,
    required String routeAlternativeId,
    TripCoordinate? currentLocation,
  }) async {
    if (!TollSession.hasToken) {
      return NetworkResponse<NavigationSessionModel>(
        errorText: 'Toll account is not connected.',
        errorCode: 'TOLL_SESSION_MISSING',
      );
    }
    try {
      final response = await client.post(
        TollApiConstants.navigationSessions,
        data: {
          'route_request_id': routeRequestId,
          'route_alternative_id': routeAlternativeId,
          if (currentLocation != null)
            'current_location': {
              'lat': currentLocation.lat,
              'lng': currentLocation.lng,
            },
        },
      );
      if (response.isSuccess) {
        return NetworkResponse<NavigationSessionModel>(
          data: NavigationSessionModel.fromJson(
            toMap(toMap(response.data)['data']),
          ),
        );
      }
      return NetworkResponse<NavigationSessionModel>(
        errorText: _errorMessage(response.data),
        errorCode: _errorCode(response.data),
      );
    } on DioException catch (e) {
      // A driver only ever has one active session (§5.1) - if one is already
      // running, the current one IS the answer to "start navigating", so
      // hand it back instead of surfacing a 409 as a failure.
      if (e.response?.statusCode == 409 &&
          _errorCode(e.response?.data) == 'NAVIGATION_ALREADY_ACTIVE') {
        final current = await getCurrentNavigationSession();
        if (current.data != null) {
          return NetworkResponse<NavigationSessionModel>(data: current.data);
        }
        return NetworkResponse<NavigationSessionModel>(
          errorText: _errorMessage(e.response?.data, 'Network error'),
          errorCode: _errorCode(e.response?.data),
        );
      }
      return NetworkResponse<NavigationSessionModel>(
        errorText: _errorMessage(e.response?.data, 'Network error'),
        errorCode: _errorCode(e.response?.data),
      );
    } catch (e) {
      return NetworkResponse<NavigationSessionModel>(errorText: e.toString());
    }
  }

  /// `GET mobile/navigation-sessions/current` — the driver's in-progress
  /// session, if any. `data: null` with no error means "nothing active",
  /// per §5.2 - not a failure.
  Future<NetworkResponse<NavigationSessionModel?>> getCurrentNavigationSession() async {
    if (!TollSession.hasToken) {
      return NetworkResponse<NavigationSessionModel?>(
        errorText: 'Toll account is not connected.',
        errorCode: 'TOLL_SESSION_MISSING',
      );
    }
    try {
      final response = await client.get(TollApiConstants.navigationSessionsCurrent);
      if (response.isSuccess) {
        final data = toMap(response.data)['data'];
        return NetworkResponse<NavigationSessionModel?>(
          data: data == null ? null : NavigationSessionModel.fromJson(toMap(data)),
        );
      }
      return NetworkResponse<NavigationSessionModel?>(
        errorText: _errorMessage(response.data),
        errorCode: _errorCode(response.data),
      );
    } on DioException catch (e) {
      return NetworkResponse<NavigationSessionModel?>(
        errorText: _errorMessage(e.response?.data, 'Network error'),
        errorCode: _errorCode(e.response?.data),
      );
    } catch (e) {
      return NetworkResponse<NavigationSessionModel?>(errorText: e.toString());
    }
  }

  /// `POST mobile/navigation-sessions/{id}/locations` — reports one GPS fix
  /// during active Driving Mode and receives back updated progress/guidance.
  Future<NetworkResponse<NavigationSessionModel>> sendNavigationLocation(
    String navigationSessionId, {
    required DateTime occurredAt,
    required double latitude,
    required double longitude,
    double? speedMph,
    double? headingDegrees,
    double? accuracyMeters,
  }) async {
    return _postNavigationAction(
      TollApiConstants.navigationSessionLocations(navigationSessionId),
      data: {
        'occurred_at': occurredAt.toUtc().toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        if (speedMph != null) 'speed_mph': speedMph,
        if (headingDegrees != null) 'heading_degrees': headingDegrees,
        if (accuracyMeters != null) 'accuracy_meters': accuracyMeters,
      },
    );
  }

  /// `POST mobile/navigation-sessions/{id}/reroute` — rebuilds guidance from
  /// [currentLocation] (or the last saved fix) when the driver goes off-route.
  Future<NetworkResponse<NavigationSessionModel>> rerouteNavigationSession(
    String navigationSessionId, {
    TripCoordinate? currentLocation,
  }) {
    return _postNavigationAction(
      TollApiConstants.navigationSessionReroute(navigationSessionId),
      data: currentLocation == null
          ? const {}
          : {
              'current_location': {
                'lat': currentLocation.lat,
                'lng': currentLocation.lng,
              },
            },
    );
  }

  /// `POST mobile/navigation-sessions/{id}/complete` — the driver reached the
  /// destination. Distinct from [cancelNavigationSession]: per §5.5/§5.6 the
  /// API treats these as different outcomes (`cancel` explicitly does not
  /// mean arrival).
  Future<NetworkResponse<NavigationSessionModel>> completeNavigationSession(
    String navigationSessionId,
  ) {
    return _postNavigationAction(
      TollApiConstants.navigationSessionComplete(navigationSessionId),
    );
  }

  /// `POST mobile/navigation-sessions/{id}/cancel` — the driver stopped
  /// before reaching the destination.
  Future<NetworkResponse<NavigationSessionModel>> cancelNavigationSession(
    String navigationSessionId,
  ) {
    return _postNavigationAction(
      TollApiConstants.navigationSessionCancel(navigationSessionId),
    );
  }

  Future<NetworkResponse<NavigationSessionModel>> _postNavigationAction(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    if (!TollSession.hasToken) {
      return NetworkResponse<NavigationSessionModel>(
        errorText: 'Toll account is not connected.',
        errorCode: 'TOLL_SESSION_MISSING',
      );
    }
    try {
      final response = await client.post(path, data: data);
      if (response.isSuccess) {
        return NetworkResponse<NavigationSessionModel>(
          data: NavigationSessionModel.fromJson(
            toMap(toMap(response.data)['data']),
          ),
        );
      }
      return NetworkResponse<NavigationSessionModel>(
        errorText: _errorMessage(response.data),
        errorCode: _errorCode(response.data),
      );
    } on DioException catch (e) {
      return NetworkResponse<NavigationSessionModel>(
        errorText: _errorMessage(e.response?.data, 'Network error'),
        errorCode: _errorCode(e.response?.data),
      );
    } catch (e) {
      return NetworkResponse<NavigationSessionModel>(errorText: e.toString());
    }
  }

  /// The toll API nests its message under `error`, unlike the izzydrive
  /// backend's flat `{detail}` / `{message}` that [dioErrorMessage] handles:
  ///   `{ "message": "...", "error": { "code": "...", "message": "..." } }`
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

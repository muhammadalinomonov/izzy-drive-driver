import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/extensions/status_code_extension.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/core/network/toll_api_constants.dart';
import 'package:taxi_app/src/core/network/toll_dio.dart';
import 'package:taxi_app/src/core/network/toll_session.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/core/utils/json_safe.dart';
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

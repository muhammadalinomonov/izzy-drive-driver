import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/extensions/status_code_extension.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/core/network/toll_api_constants.dart';
import 'package:taxi_app/src/core/network/toll_dio.dart';
import 'package:taxi_app/src/core/network/toll_session.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/core/utils/json_safe.dart';
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

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:taxi_app/core/extensions/status_code_extension.dart';
import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/core/network/toll_api_constants.dart';
import 'package:taxi_app/core/network/toll_dio.dart';
import 'package:taxi_app/core/network/toll_session.dart';
import 'package:taxi_app/core/service_locater.dart';
import 'package:taxi_app/core/utils/json_safe.dart';
import 'package:taxi_app/features/trips/data/model/route_support_model.dart';

/// Route-review support thread: creates the review
/// (`docs/mobile-fuel-api-websocket.md` §4.1) and posts follow-ups to it
/// (`docs/mobile-api.md` §8.3).
@lazySingleton
class RouteSupportDataSource {
  RouteSupportDataSource();

  final client = serviceLocator.get<TollDioSettings>().dio;

  /// `POST mobile/route-reviews`. Requires bootstrap's
  /// `services.route_review.available=true` server-side; a driver without it
  /// gets `403 MOBILE_ROUTE_REVIEW_NOT_ENABLED`, surfaced like any other error.
  Future<NetworkResponse<RouteReviewThread>> startReview(
    RouteSupportRequest request, {
    required String idempotencyKey,
  }) async {
    if (!TollSession.hasToken) {
      return NetworkResponse<RouteReviewThread>(
        errorText: 'Toll account is not connected.',
        errorCode: 'TOLL_SESSION_MISSING',
      );
    }
    try {
      final response = await client.post(
        TollApiConstants.routeReviews,
        data: request.toCreateReviewJson(),
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
      );
      if (response.isSuccess) {
        return NetworkResponse<RouteReviewThread>(
          data: RouteReviewThread.fromJson(toMap(toMap(response.data)['data'])),
        );
      }
      return NetworkResponse<RouteReviewThread>(
        errorText: _errorMessage(response.data),
        errorCode: _errorCode(response.data),
      );
    } on DioException catch (e) {
      return NetworkResponse<RouteReviewThread>(
        errorText: _errorMessage(e.response?.data, 'Network error'),
        errorCode: _errorCode(e.response?.data),
      );
    } catch (e) {
      return NetworkResponse<RouteReviewThread>(errorText: e.toString());
    }
  }

  /// `POST mobile/route-reviews/{id}/messages` (docs §8.3). No idempotency
  /// key exists for this one - a timed-out send is not safe to blindly retry.
  Future<NetworkResponse<RouteReviewThread>> sendMessage({
    required String routeReviewId,
    required String text,
  }) async {
    if (!TollSession.hasToken) {
      return NetworkResponse<RouteReviewThread>(
        errorText: 'Toll account is not connected.',
        errorCode: 'TOLL_SESSION_MISSING',
      );
    }
    try {
      final response = await client.post(
        TollApiConstants.routeReviewMessages(routeReviewId),
        data: {'message': text},
      );
      if (response.isSuccess) {
        return NetworkResponse<RouteReviewThread>(
          data: RouteReviewThread.fromJson(toMap(toMap(response.data)['data'])),
        );
      }
      return NetworkResponse<RouteReviewThread>(
        errorText: _errorMessage(response.data),
        errorCode: _errorCode(response.data),
      );
    } on DioException catch (e) {
      return NetworkResponse<RouteReviewThread>(
        errorText: _errorMessage(e.response?.data, 'Network error'),
        errorCode: _errorCode(e.response?.data),
      );
    } catch (e) {
      return NetworkResponse<RouteReviewThread>(errorText: e.toString());
    }
  }

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

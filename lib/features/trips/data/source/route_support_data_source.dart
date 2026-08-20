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

/// Route-review support thread (docs/mobile-chat-route-fuel-drive.md §4/§5).
///
/// Every call here answers with the same whole route-review object, which is
/// the point: the screen never assembles state out of individual responses or
/// events, it replaces it from the latest review it has read.
@lazySingleton
class RouteSupportDataSource {
  RouteSupportDataSource();

  final client = serviceLocator.get<TollDioSettings>().dio;

  /// `POST mobile/route-reviews` (§4.2). Requires bootstrap's
  /// `services.route_review.available=true` server-side; a driver without it
  /// gets `403 MOBILE_ROUTE_REVIEW_NOT_ENABLED`, surfaced like any other error.
  Future<NetworkResponse<RouteReviewDetail>> startReview(
    RouteSupportRequest request, {
    required String idempotencyKey,
  }) {
    return _review(
      () => client.post(
        TollApiConstants.routeReviews,
        data: request.toCreateReviewJson(),
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
      ),
    );
  }

  /// `GET mobile/route-reviews/{id}` (§4.2) — re-reads the review after
  /// anything says it changed. The only way dispatcher decisions, suggested
  /// alternatives and fuel recommendations ever reach the client.
  Future<NetworkResponse<RouteReviewDetail>> fetchReview(String routeReviewId) {
    return _review(
      () => client.get(TollApiConstants.routeReviewDetail(routeReviewId)),
    );
  }

  /// `POST mobile/route-reviews/{id}/messages` (docs/mobile-api.md §8.3). No
  /// idempotency key exists for this one - a timed-out send is not safe to
  /// blindly retry (docs/mobile-chat-route-fuel-drive.md §3).
  Future<NetworkResponse<RouteReviewDetail>> sendMessage({
    required String routeReviewId,
    required String text,
  }) {
    return _review(
      () => client.post(
        TollApiConstants.routeReviewMessages(routeReviewId),
        data: {'message': text},
      ),
    );
  }

  /// `POST .../fuel-recommendations/{id}/confirm` (§5) — the driver accepting
  /// a dispatcher-recommended stop. Body is an empty object by contract, not
  /// an omission.
  Future<NetworkResponse<RouteReviewDetail>> confirmFuelRecommendation({
    required String routeReviewId,
    required String recommendationId,
  }) {
    return _review(
      () => client.post(
        TollApiConstants.routeReviewFuelConfirm(
          routeReviewId,
          recommendationId,
        ),
        data: const <String, dynamic>{},
      ),
    );
  }

  /// Shared envelope handling: every endpoint on this screen returns the full
  /// review under `data`, so they differ only in the request they issue.
  Future<NetworkResponse<RouteReviewDetail>> _review(
    Future<Response<dynamic>> Function() send,
  ) async {
    if (!TollSession.hasToken) {
      return NetworkResponse<RouteReviewDetail>(
        errorText: 'Toll account is not connected.',
        errorCode: 'TOLL_SESSION_MISSING',
      );
    }
    try {
      final response = await send();
      if (response.isSuccess) {
        return NetworkResponse<RouteReviewDetail>(
          data: RouteReviewDetail.fromJson(
            toMap(toMap(response.data)['data']),
          ),
        );
      }
      return NetworkResponse<RouteReviewDetail>(
        errorText: _errorMessage(response.data),
        errorCode: _errorCode(response.data),
      );
    } on DioException catch (e) {
      return NetworkResponse<RouteReviewDetail>(
        errorText: _errorMessage(e.response?.data, 'Network error'),
        errorCode: _errorCode(e.response?.data),
      );
    } catch (e) {
      return NetworkResponse<RouteReviewDetail>(errorText: e.toString());
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

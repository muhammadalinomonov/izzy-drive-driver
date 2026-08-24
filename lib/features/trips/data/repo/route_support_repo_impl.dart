import 'package:injectable/injectable.dart';
import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/trips/data/model/route_support_model.dart';
import 'package:taxi_app/features/trips/data/source/route_support_data_source.dart';
import 'package:taxi_app/features/trips/domain/repo/route_support_repo.dart';

@LazySingleton(as: RouteSupportRepo)
class RouteSupportRepoImpl extends RouteSupportRepo {
  final RouteSupportDataSource dataSource;

  RouteSupportRepoImpl({required this.dataSource});

  @override
  Future<NetworkResponse<RouteReviewDetail>> startReview(
    RouteSupportRequest request, {
    required String idempotencyKey,
  }) {
    return dataSource.startReview(request, idempotencyKey: idempotencyKey);
  }

  @override
  Future<NetworkResponse<RouteReviewDetail>> fetchReview(String routeReviewId) {
    return dataSource.fetchReview(routeReviewId);
  }

  @override
  Future<NetworkResponse<RouteReviewDetail>> sendMessage({
    required String routeReviewId,
    required String text,
  }) {
    return dataSource.sendMessage(routeReviewId: routeReviewId, text: text);
  }

  @override
  Future<NetworkResponse<RouteReviewDetail>> confirmFuelRecommendation({
    required String routeReviewId,
    required String recommendationId,
  }) {
    return dataSource.confirmFuelRecommendation(
      routeReviewId: routeReviewId,
      recommendationId: recommendationId,
    );
  }

  @override
  Future<NetworkResponse<RouteReviewDetail>> cancelReview(
    String routeReviewId,
  ) {
    return dataSource.cancelReview(routeReviewId);
  }
}

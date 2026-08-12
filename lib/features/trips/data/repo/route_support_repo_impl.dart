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
  Future<NetworkResponse<RouteReviewThread>> startReview(
    RouteSupportRequest request, {
    required String idempotencyKey,
  }) {
    return dataSource.startReview(request, idempotencyKey: idempotencyKey);
  }

  @override
  Future<NetworkResponse<RouteReviewThread>> sendMessage({
    required String routeReviewId,
    required String text,
  }) {
    return dataSource.sendMessage(routeReviewId: routeReviewId, text: text);
  }
}

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
  Future<NetworkResponse<List<RouteSupportMessage>>> getConversation(
    RouteSupportRequest request,
  ) {
    return dataSource.getConversation(request);
  }

  @override
  Future<NetworkResponse<RouteSupportMessage>> sendMessage({
    required RouteSupportRequest request,
    required String text,
  }) {
    return dataSource.sendMessage(request: request, text: text);
  }
}

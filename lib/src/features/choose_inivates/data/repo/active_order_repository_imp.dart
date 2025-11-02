import '../../../../core/network/network_response.dart';
import '../../domain/active_order_repository.dart';
import '../source/active_order_source.dart';

class ActiveOrderRepositoryImpl extends ActiveOrderRepository {
  final ActiveOrderSource activeOrderSource;

  ActiveOrderRepositoryImpl({required this.activeOrderSource});

  @override
  Future<NetworkResponse> fetchActiveOrder() => activeOrderSource.fetchActiveOrder();

  @override
  Future<NetworkResponse> updateOrderPrice(double price) {
    return activeOrderSource.updateOrderPrice(price);
  }
}

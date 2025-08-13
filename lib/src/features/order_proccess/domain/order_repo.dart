import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/features/order_proccess/data/order_proccess_source.dart';
import 'package:taxi_app/src/utils/local.dart';
import '../../../core/network/network_response.dart';

abstract class OrderRepository {
  Future<NetworkResponse> getMe();
  Future<NetworkResponse> cancelOrder(String orderID);
}

class OrderRepositoryImpl implements OrderRepository {
  final OrderProccessSource orderProccessSource;

  OrderRepositoryImpl({
    required this.orderProccessSource,
  });




  @override
  Future<NetworkResponse> getMe() {
    return orderProccessSource.getMe();
  }

  @override
  Future<NetworkResponse> cancelOrder(String orderId) {
    return orderProccessSource.cancelOrder(orderId);
  }
}

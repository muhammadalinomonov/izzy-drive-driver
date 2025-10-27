import 'package:taxi_app/src/features/order_proccess/data/order_proccess_source.dart';
import 'package:taxi_app/src/features/order_proccess/domain/entities/current_order_entity.dart';

import '../../../core/network/network_response.dart';

abstract class OrderRepository {
  Future<NetworkResponse> getMe();

  Future<NetworkResponse> cancelOrder(String orderID);

  Future<NetworkResponse<CurrentOrderEntity>> getCurrentOrder();

  Future<void> changeSubOrderStatus(int id, String status);

  Future<NetworkResponse<int>> doneCurrentOrder();

  Future<NetworkResponse<void>> rateMechanic(int rating, String comment, int mechanicId);
}

class OrderRepositoryImpl implements OrderRepository {
  final OrderProccessSource orderProccessSource;

  OrderRepositoryImpl({required this.orderProccessSource});

  @override
  Future<NetworkResponse> getMe() {
    return orderProccessSource.getMe();
  }

  @override
  Future<NetworkResponse> cancelOrder(String orderId) {
    return orderProccessSource.cancelOrder(orderId);
  }

  @override
  Future<NetworkResponse<CurrentOrderEntity>> getCurrentOrder() async {
    return orderProccessSource.getCurrentOrder();
  }

  @override
  Future<void> changeSubOrderStatus(int id, String status) {
    return orderProccessSource.changeSubOrderStatus(status: status, id: id);
  }

  @override
  Future<NetworkResponse<int>> doneCurrentOrder() {
    return orderProccessSource.doneCurrentOrder();
  }

  @override
  Future<NetworkResponse<void>> rateMechanic(int rating, String comment, int mechanicId) {
    return orderProccessSource.rateMaster(rating, comment, mechanicId);
  }
}

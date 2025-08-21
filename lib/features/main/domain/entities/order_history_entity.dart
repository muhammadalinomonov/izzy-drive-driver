import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mechanic/features/main/data/models/order_history_model.dart';

class OrderHistoryEntity extends Equatable {
  final int id;
  final String orderTitle;
  final double orderPrice;
  final String address;

  const OrderHistoryEntity({
    this.id = -1,
    this.orderTitle = '',
    this.orderPrice = 0,
    this.address = '',
  });

  @override
  List<Object?> get props => [id, orderTitle, orderPrice, address];
}

class OrderHistoryEntityConverter implements JsonConverter<OrderHistoryEntity, Map<String, dynamic>> {

  const OrderHistoryEntityConverter();
  @override
  OrderHistoryEntity fromJson(Map<String, dynamic> json) {
    return OrderHistoryModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(OrderHistoryEntity object) {
    return {};
  }
}

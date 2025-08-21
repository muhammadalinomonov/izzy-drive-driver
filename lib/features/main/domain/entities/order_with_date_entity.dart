import 'package:equatable/equatable.dart';
import 'package:mechanic/features/main/domain/entities/order_history_entity.dart';

class OrdersWithDataEntity extends Equatable{
  final String date;
  @OrderHistoryEntityConverter()
  final List<OrderHistoryEntity> orders;

  const OrdersWithDataEntity({
    this.date = '',
    this.orders = const [],
  });

  @override
  List<Object?> get props => [date, orders];
}
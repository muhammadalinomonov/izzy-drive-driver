part of 'orders_history_bloc.dart';

@immutable
sealed class OrdersHistoryEvent {}

class GetOrdersHistoryEvent extends OrdersHistoryEvent {}

class GetMoreOrdersHistoryEvent extends OrdersHistoryEvent {}

class GetOrderHistoryDetailEvent extends OrdersHistoryEvent {
  final int orderId;

  GetOrderHistoryDetailEvent({required this.orderId});
}

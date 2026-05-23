part of 'orders_history_bloc.dart';

@immutable
sealed class OrdersHistoryEvent {}

class GetOrdersHistoryEvent extends OrdersHistoryEvent {
  /// When true, skip emitting `inProgress` if we already have history items -
  /// used by pull-to-refresh so the list doesn't collapse into a spinner
  /// while the user is staring at it.
  final bool silent;

  GetOrdersHistoryEvent({this.silent = false});
}

class GetMoreOrdersHistoryEvent extends OrdersHistoryEvent {}

class GetOrderHistoryDetailEvent extends OrdersHistoryEvent {
  final int orderId;

  GetOrderHistoryDetailEvent({required this.orderId});
}

part of 'orders_bloc.dart';

@immutable
class OrdersEvent {}

class GetOrdersEvent extends OrdersEvent {
  final String? status;
  final String? mechanicId;

  GetOrdersEvent({this.status, this.mechanicId});
}

class GetMoreOrdersEvent extends OrdersEvent {}

class GetOrderDetailEvent extends OrdersEvent {
  final int orderId;

  GetOrderDetailEvent({required this.orderId});
}

class CancelOrderEvent extends OrdersEvent {
  CancelOrderEvent();
}

class SendApplicationEvent extends OrdersEvent {
  final int orderId;
  final String? comment;
  final String proposedPrice;

  SendApplicationEvent({required this.orderId, this.comment, required this.proposedPrice});
}

class ConnectToWebSocketEvent extends OrdersEvent {}

class DisConnectFromWebSocketEvent extends OrdersEvent {}

class GetCurrentOrderEvent extends OrdersEvent {}

class ChangeSubOrderStatusEvent extends OrdersEvent {
  final int id;
  final String status;

  ChangeSubOrderStatusEvent({required this.id, required this.status});
}

class DoneCurrentOrderEvent extends OrdersEvent {
  final Function(int code) onSuccess;

  DoneCurrentOrderEvent({required this.onSuccess});
}

class RateMasterEvent extends OrdersEvent {
  final int star;
  final String comment;
  final int mechanicId;

  RateMasterEvent( {required this.star, required this.comment, required this.mechanicId});
}

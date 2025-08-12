part of 'orders_bloc.dart';

@immutable
class OrdersEvent {}

class GetOrdersEvent extends OrdersEvent {
  final String? status;
  final String? mechanicId;

  GetOrdersEvent({this.status, this.mechanicId});
}

class GetMoreOrdersEvent extends OrdersEvent {}

class GetCurrentOrderEvent extends OrdersEvent {}

class GetOrderDetailEvent extends OrdersEvent {
  final int orderId;

  GetOrderDetailEvent({required this.orderId});
}

class SendApplicationEvent extends OrdersEvent {
  final int orderId;
  final String? comment;
  final String proposedPrice;

  SendApplicationEvent({
    required this.orderId,
    this.comment,
    required this.proposedPrice,
  });
}

class ConnectToWebSocketEvent extends OrdersEvent {}

class DisConnectFromWebSocketEvent extends OrdersEvent {}

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


class _UpdateOrderAsSelectedMechanicEvent extends OrdersEvent {
  final int orderId;

  _UpdateOrderAsSelectedMechanicEvent({required this.orderId});
}

class GetSelectedOrderEvent extends OrdersEvent {
  final int orderId;

  GetSelectedOrderEvent({required this.orderId});
}
class ChangeOrderStatusEvent extends OrdersEvent {
  final int orderId;
  final String status;

  ChangeOrderStatusEvent({
    required this.orderId,
    required this.status,
  });
}

class AddNewServiceEvent extends OrdersEvent {
  final String serviceName;
  final double servicePrice;

  AddNewServiceEvent({
    required this.serviceName,
    required this.servicePrice,
  });
}

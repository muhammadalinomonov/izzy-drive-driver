part of 'orders_bloc.dart';

@immutable
class OrdersEvent {}

class CancelOrderEvent extends OrdersEvent {
  CancelOrderEvent();
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

  RateMasterEvent({required this.star, required this.comment, required this.mechanicId});
}

class ClearLifecycleEventEvent extends OrdersEvent {}

class ClearPendingSubOrderEvent extends OrdersEvent {}
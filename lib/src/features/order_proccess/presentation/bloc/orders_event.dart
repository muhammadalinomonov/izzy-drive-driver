part of 'orders_bloc.dart';

@immutable
class OrdersEvent {}

class CancelOrderEvent extends OrdersEvent {
  CancelOrderEvent();
}

class ConnectToWebSocketEvent extends OrdersEvent {}

class DisConnectFromWebSocketEvent extends OrdersEvent {}

class _WsMessageReceivedEvent extends OrdersEvent {
  final Map<String, dynamic> data;
  _WsMessageReceivedEvent(this.data);
}

class GetCurrentOrderEvent extends OrdersEvent {
  /// When true, skip emitting `inProgress` if we already have order data —
  /// used for lifecycle resume / WS reconnect refresh so the UI doesn't
  /// flash a shimmer over already-rendered content.
  final bool silent;

  GetCurrentOrderEvent({this.silent = false});
}

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

/// Boshqa joydan (masalan `InivitesBloc.cancelOrder` API chaqirilgandan
/// keyin) `OrdersBloc.state.currentOrder`'ni clear qilish uchun. API
/// qaytadan chaqirilmaydi — bu signal-only event.
class ResetCurrentOrderEvent extends OrdersEvent {}
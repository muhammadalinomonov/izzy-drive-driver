part of 'inivites_bloc.dart';

@immutable
sealed class InivitesEvent {}

class FetchActiveOrderEvent extends InivitesEvent {}

class ConnectToWebSocketEvent extends InivitesEvent {}

class DisconnectFromWebSocketEvent extends InivitesEvent {}

class NewProposalReceivedEvent extends InivitesEvent {
  final OrderData newProposal;

  NewProposalReceivedEvent(this.newProposal);
}

class UpdateOrderPriceEvent extends InivitesEvent {
  final double price;

  UpdateOrderPriceEvent({required this.price});
}

class CancelActiveOrderEvent extends InivitesEvent {}

class _WsMessageReceivedEvent extends InivitesEvent {
  final Map<String, dynamic> data;
  _WsMessageReceivedEvent(this.data);
}

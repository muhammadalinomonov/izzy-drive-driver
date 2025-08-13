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
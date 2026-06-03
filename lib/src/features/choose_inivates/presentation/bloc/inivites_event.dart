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

class CancelActiveOrderEvent extends InivitesEvent {
  /// Backend-defined reason id picked from the cancel-reason sheet.
  /// Mutually exclusive with [reasonText].
  final int? reasonId;

  /// Free-form text from the sheet's "Other" row. Mutually exclusive
  /// with [reasonId].
  final String? reasonText;

  CancelActiveOrderEvent({this.reasonId, this.reasonText});
}

class _WsMessageReceivedEvent extends InivitesEvent {
  final Map<String, dynamic> data;
  _WsMessageReceivedEvent(this.data);
}

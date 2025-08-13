import 'package:equatable/equatable.dart';

sealed class ProposalEvent extends Equatable {
  const ProposalEvent();

  @override
  List<Object> get props => [];
}

class GetProposalEvent extends ProposalEvent {
  final int id;

  const GetProposalEvent({required this.id});

  @override
  List<Object> get props => [id];
}

class SelectProposalEvent extends ProposalEvent {
  final int proposalId;

  const SelectProposalEvent({required this.proposalId});

  @override
  List<Object> get props => [proposalId];
}

class NewOrderEvent extends ProposalEvent {
  final Map<String, dynamic> routeData; // Pass the route data from the API response

  const NewOrderEvent({required this.routeData});

  @override
  List<Object> get props => [routeData];
}

class UpdateProposalEvent extends ProposalEvent {
  final int id;

  const UpdateProposalEvent({required this.id});

  @override
  List<Object> get props => [id];
}

class CancelProposalEvent extends ProposalEvent {
  final int proposalId;

  const CancelProposalEvent({required this.proposalId});

  @override
  List<Object> get props => [proposalId];
}
part of 'proposal_bloc.dart';

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

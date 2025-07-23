part of 'proposal_bloc.dart';

enum ProposalStatus { initial, loading, loaded, error }

class ProposalState extends Equatable {
  final ProposalStatus status;

  const ProposalState({required this.status});

  @override
  List<Object> get props => [status];
}

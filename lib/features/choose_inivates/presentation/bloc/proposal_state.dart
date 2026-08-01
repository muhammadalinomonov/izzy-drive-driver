import 'package:equatable/equatable.dart';
import '../../data/model/proposal_model.dart';

enum ProposalStatus { initial, loading, loaded, error }

class ProposalState extends Equatable {
  final ProposalStatus status;
  final Proposal? proposal; // Existing proposal data
  final Map<String, dynamic>? route; // New field for route data
  final String? errorMessage;

  const ProposalState({
    required this.status,
    this.proposal,
    this.route,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, proposal, route, errorMessage];
}
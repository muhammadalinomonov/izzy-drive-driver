import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/features/choose_inivates/presentation/bloc/proposal_event.dart';
import 'package:taxi_app/features/choose_inivates/presentation/bloc/proposal_state.dart';

import '../../../home/domain/repository/home_repository.dart';
import '../../data/model/proposal_model.dart';

class ProposalBloc extends Bloc<ProposalEvent, ProposalState> {
  final HomeRepository homeRepository;

  ProposalBloc(this.homeRepository) : super(const ProposalState(status: ProposalStatus.initial)) {
    on<GetProposalEvent>((event, emit) async {
      emit(const ProposalState(status: ProposalStatus.loading));
      try {
        final result = await homeRepository.getProsal(event.id);
        if (result.errorText.isEmpty && result.data != null) {
          final proposalData = result.data['data'] as Map<String, dynamic>?;
          if (proposalData != null) {
            final proposal = Proposal.fromJson(proposalData);
            emit(ProposalState(status: ProposalStatus.loaded, proposal: proposal));
          } else {
            emit(const ProposalState(status: ProposalStatus.error, errorMessage: 'No proposal data received'));
          }
        } else {
          emit(
            ProposalState(
              status: ProposalStatus.error,
              errorMessage: result.errorText.isEmpty ? 'No data received' : result.errorText,
            ),
          );
        }
      } catch (e) {
        emit(ProposalState(status: ProposalStatus.error, errorMessage: 'Failed to parse proposal: $e'));
      }
    });

    on<SelectProposalEvent>((event, emit) async {
      final previousProposal = state.proposal; // save before loading clears it
      emit(const ProposalState(status: ProposalStatus.loading));
      final result = await homeRepository.selectProposal(event.proposalId);
      if (result.errorText.isEmpty && result.data != null) {
        emit(
          ProposalState(
            status: ProposalStatus.loaded,
            proposal: previousProposal, // retained from before loading
            route: result.data as Map<String, dynamic>,
          ),
        );
      } else {
        emit(
          ProposalState(
            status: ProposalStatus.error,
            errorMessage: result.errorText.isEmpty ? 'Selection failed' : result.errorText,
          ),
        );
      }
    });
  }
}

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:taxi_app/src/features/home/domain/repository/home_repository.dart';

part 'proposal_event.dart';
part 'proposal_state.dart';

class ProposalBloc extends Bloc<ProposalEvent, ProposalState> {
  final HomeRepository homeRepository;

  ProposalBloc(this.homeRepository)
    : super(ProposalState(status: ProposalStatus.initial)) {
    on<GetProposalEvent>((event, emit) async {
      final result = await homeRepository.getProsal(event.id);
      if (result.errorText.isEmpty) {
        emit(ProposalState(status: ProposalStatus.loaded));
      } else {
        emit(ProposalState(status: ProposalStatus.error));
      }
    });
  }
}

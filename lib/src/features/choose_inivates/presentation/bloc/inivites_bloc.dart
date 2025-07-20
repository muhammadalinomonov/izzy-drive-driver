import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../data/model/active_order.dart';
import '../../domain/active_order_repository.dart';

part 'inivites_event.dart';

part 'inivites_state.dart';

class InivitesBloc extends Bloc<InivitesEvent, InivitesState> {
  final ActiveOrderRepository activeOrderRepository;

  InivitesBloc({required this.activeOrderRepository})
    : super(InivitesInitial()) {
    on<FetchActiveOrderEvent>((event, emit) async {
      emit(InivitesLoading());
      try {
        final response = await activeOrderRepository.fetchActiveOrder();
        if (response.data != null) {
          emit(InivitesLoaded(response.data as OrderResponse));
        } else {
          emit(InivitesError(response.errorText ?? 'Unknown error'));
        }
      } catch (e) {
        emit(InivitesError(e.toString()));
      }
    });
  }
}

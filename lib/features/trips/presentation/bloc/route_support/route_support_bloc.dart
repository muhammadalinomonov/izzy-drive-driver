import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/features/trips/data/model/route_support_model.dart';
import 'package:taxi_app/features/trips/domain/repo/route_support_repo.dart';

part 'route_support_event.dart';
part 'route_support_state.dart';

/// Backs the route support thread (docs/ui/8-2.png).
///
/// Hand-built in its route builder rather than resolved from GetIt: it takes
/// the whole [RouteSupportRequest] as a runtime argument, which is more than
/// `@factoryParam` carries comfortably - same reason `RouteOverviewBloc` is
/// built there. Its dependency still comes from the container.
class RouteSupportBloc extends Bloc<RouteSupportEvent, RouteSupportState> {
  final RouteSupportRepo repo;

  /// The route the conversation is about. Fixed for the life of the page.
  final RouteSupportRequest request;

  RouteSupportBloc({required this.repo, required this.request})
      : super(const RouteSupportState()) {
    on<RouteSupportStarted>(_onStarted);
    on<RouteSupportMessageSent>(_onMessageSent);
  }

  Future<void> _onStarted(
    RouteSupportStarted event,
    Emitter<RouteSupportState> emit,
  ) async {
    emit(state.copyWith(
      status: RouteSupportStatus.loading,
      errorMessage: '',
    ));

    final response = await repo.getConversation(request);
    if (response.errorText.isNotEmpty || response.data == null) {
      emit(state.copyWith(
        status: RouteSupportStatus.failure,
        errorMessage: response.errorText,
      ));
      return;
    }

    emit(state.copyWith(
      status: RouteSupportStatus.ready,
      messages: response.data,
    ));
  }

  Future<void> _onMessageSent(
    RouteSupportMessageSent event,
    Emitter<RouteSupportState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty || state.sending) return;

    emit(state.copyWith(sending: true, sendError: ''));

    final response = await repo.sendMessage(request: request, text: text);
    if (response.errorText.isNotEmpty || response.data == null) {
      emit(state.copyWith(sending: false, sendError: response.errorText));
      return;
    }

    emit(state.copyWith(
      sending: false,
      // The thread only ever grows here, so appending is enough - no refetch,
      // which would also throw away anything typed since.
      messages: [...state.messages, response.data!],
      // A first message on an empty thread is what turns the empty state into
      // a conversation.
      status: RouteSupportStatus.ready,
    ));
  }
}

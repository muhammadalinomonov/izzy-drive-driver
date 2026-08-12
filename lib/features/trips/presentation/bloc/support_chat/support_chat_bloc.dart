import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:taxi_app/core/session/premium_session.dart';
import 'package:taxi_app/features/trips/data/model/support_chat_model.dart';
import 'package:taxi_app/features/trips/domain/repo/support_chat_repo.dart';

part 'support_chat_event.dart';
part 'support_chat_state.dart';

/// Backs `support_message_page.dart` - the normal support conversation shared
/// by the trip planner, route overview and driving mode (docs/mobile-api.md
/// §8.1/§8.2).
///
/// Premium-gated per the task brief: every entry point already hides its
/// launcher behind [PremiumSession.isPremium] (see `PremiumSupportButton`),
/// but this checks again on start so the page is never left hitting the API
/// for a driver who lost the entitlement or reached it some other way.
@injectable
class SupportChatBloc extends Bloc<SupportChatEvent, SupportChatState> {
  final SupportChatRepo repo;

  SupportChatBloc({required this.repo}) : super(const SupportChatState()) {
    on<SupportChatStarted>(_onStarted);
    on<SupportChatMessageSent>(_onMessageSent);
  }

  Future<void> _onStarted(
    SupportChatStarted event,
    Emitter<SupportChatState> emit,
  ) async {
    if (!PremiumSession.isPremium) {
      emit(state.copyWith(status: SupportChatStatus.restricted));
      return;
    }

    emit(state.copyWith(status: SupportChatStatus.loading, errorMessage: ''));

    final response = await repo.fetchHistory();
    if (response.errorText.isNotEmpty || response.data == null) {
      emit(state.copyWith(
        status: SupportChatStatus.failure,
        errorMessage: response.errorText,
      ));
      return;
    }

    emit(state.copyWith(
      status: SupportChatStatus.ready,
      // The API answers newest-first; the thread reads top-to-bottom oldest
      // first, so the single loaded page is reversed once here rather than
      // asking every render to re-derive display order.
      messages: response.data!.items.reversed.toList(),
    ));
  }

  Future<void> _onMessageSent(
    SupportChatMessageSent event,
    Emitter<SupportChatState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty || state.sending) return;

    emit(state.copyWith(sending: true, sendError: ''));

    final response = await repo.sendMessage(text);
    if (response.errorText.isNotEmpty || response.data == null) {
      // The typed message is already cleared from the composer by the page;
      // surfacing only the error (not restoring the text) matches how
      // RouteSupportBloc handles the same failure, so a retry is a deliberate
      // re-type rather than a silent resend of stale input.
      emit(state.copyWith(sending: false, sendError: response.errorText));
      return;
    }

    emit(state.copyWith(
      sending: false,
      messages: [...state.messages, response.data!],
      status: SupportChatStatus.ready,
    ));
  }
}

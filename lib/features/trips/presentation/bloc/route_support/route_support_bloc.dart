import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/features/trips/data/model/route_support_model.dart';
import 'package:taxi_app/features/trips/data/model/support_chat_model.dart';
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

  /// Generated once per bloc instance - i.e. once per page visit - and reused
  /// across every create attempt for that visit, including a manual retry.
  /// The API dedupes `POST /mobile/route-reviews` by this key, so a retry
  /// after a timeout resolves to the original review instead of creating a
  /// second one; a fresh page visit later gets its own bloc and its own key,
  /// which is correctly a new attempt.
  final String _createIdempotencyKey =
      'mobile-route-review-${DateTime.now().millisecondsSinceEpoch}';

  /// Set once [_onStarted] succeeds. Every follow-up message posts to this.
  String? _routeReviewId;

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

    final response = await repo.startReview(
      request,
      idempotencyKey: _createIdempotencyKey,
    );
    if (response.errorText.isNotEmpty || response.data == null) {
      emit(state.copyWith(
        status: RouteSupportStatus.failure,
        errorMessage: response.errorText,
      ));
      return;
    }

    _routeReviewId = response.data!.id;
    emit(state.copyWith(
      status: RouteSupportStatus.ready,
      // Oldest-first already, per docs/mobile-api.md §8.3/§4.2.
      messages: response.data!.messages,
    ));
  }

  Future<void> _onMessageSent(
    RouteSupportMessageSent event,
    Emitter<RouteSupportState> emit,
  ) async {
    final text = event.text.trim();
    final routeReviewId = _routeReviewId;
    if (text.isEmpty || state.sending || routeReviewId == null) return;

    emit(state.copyWith(sending: true, sendError: ''));

    final response = await repo.sendMessage(
      routeReviewId: routeReviewId,
      text: text,
    );
    if (response.errorText.isNotEmpty || response.data == null) {
      emit(state.copyWith(sending: false, sendError: response.errorText));
      return;
    }

    emit(state.copyWith(
      sending: false,
      // Full replace, not append: the response is the whole review's
      // messages, not just the one that was just posted (docs §8.3).
      messages: response.data!.messages,
      status: RouteSupportStatus.ready,
    ));
  }
}

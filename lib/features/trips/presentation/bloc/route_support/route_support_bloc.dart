import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/core/location_service.dart';
import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/core/network/toll_session.dart';
import 'package:taxi_app/core/service_locater.dart';
import 'package:taxi_app/core/services/toll_reverb_service.dart';
import 'package:taxi_app/core/utils/json_safe.dart';
import 'package:taxi_app/features/trips/data/model/navigation_session_model.dart';
import 'package:taxi_app/features/trips/data/model/route_support_model.dart';
import 'package:taxi_app/features/trips/data/model/support_chat_model.dart';
import 'package:taxi_app/features/trips/data/model/trip_model.dart';
import 'package:taxi_app/features/trips/domain/repo/route_support_repo.dart';
import 'package:taxi_app/features/trips/domain/repo/trips_repo.dart';

part 'route_support_event.dart';
part 'route_support_state.dart';

/// Backs the route support thread (docs/ui/8-2.png), implementing the loop in
/// `docs/mobile-chat-route-fuel-drive.md`:
///
/// ```text
/// REST mutation -> "this review changed" -> GET the review -> replace state
/// ```
///
/// Nothing on this screen is assembled from a message. A dispatcher approving
/// the route, suggesting a different alternative, attaching a fuel stop or
/// closing the review all surface the same way - as fields on the review read
/// back over REST - so every handler here ends by replacing [state.review]
/// wholesale rather than patching pieces of it.
///
/// Hand-built in its route builder rather than resolved from GetIt: it takes
/// the whole [RouteSupportPageArgs] as a runtime argument, which is more than
/// `@factoryParam` carries comfortably - same reason `RouteOverviewBloc` is
/// built there. Its dependencies still come from the container.
///
/// `RouteSupportPage`'s 15s poll timer stays as-is for now - see
/// [TollReverbService]'s class doc for why it silently no-ops without a
/// configured Reverb host. Once `_reverb` is subscribed, both frames it can
/// receive for this review (`support.message.created` for its own id,
/// `mobile.route-review.updated`) reduce to the exact same
/// [RouteSupportRefreshed] the poll timer already fires - one refetch path,
/// just triggered sooner when the socket is actually delivering.
class RouteSupportBloc extends Bloc<RouteSupportEvent, RouteSupportState> {
  final RouteSupportRepo repo;

  /// Only for Drive: the navigation session lives on the trips repo, since it
  /// is the same session the route overview's Start button opens.
  final TripsRepo tripsRepo;

  final LocationService locationService;

  final TollReverbService _reverb = serviceLocator<TollReverbService>();
  StreamSubscription<Map<String, dynamic>>? _reverbMessageSub;
  StreamSubscription<Map<String, dynamic>>? _reverbReviewSub;
  bool _reverbRetained = false;

  /// `support.message.created` ids and `mobile.route-review.updated`
  /// `event_id`s already turned into a `RouteSupportRefreshed`, so a
  /// redelivered frame (reconnect) does not trigger a second refetch.
  final Set<String> _seenSocketMessageIds = {};
  final Set<String> _seenReviewEventIds = {};

  /// How this page was opened - creating a new review, or opening one that
  /// already exists. See [RouteSupportPageArgs].
  final RouteSupportPageArgs args;

  /// Generated once per bloc instance - i.e. once per page visit - and reused
  /// across every create attempt for that visit, including a manual retry.
  /// The API dedupes `POST /mobile/route-reviews` by this key, so a retry
  /// after a timeout resolves to the original review instead of creating a
  /// second one; a fresh page visit later gets its own bloc and its own key,
  /// which is correctly a new attempt.
  final String _createIdempotencyKey =
      'mobile-route-review-${DateTime.now().millisecondsSinceEpoch}';

  RouteSupportBloc({
    required this.repo,
    required this.tripsRepo,
    required this.locationService,
    required this.args,
  }) : super(const RouteSupportState()) {
    on<RouteSupportStarted>(_onStarted);
    on<RouteSupportRefreshed>(_onRefreshed);
    on<RouteSupportMessageSent>(_onMessageSent);
    on<RouteSupportFuelConfirmed>(_onFuelConfirmed);
    on<RouteSupportDrivePressed>(_onDrivePressed);
    on<RouteSupportCancelled>(_onCancelled);
  }

  Future<void> _onStarted(
    RouteSupportStarted event,
    Emitter<RouteSupportState> emit,
  ) async {
    emit(state.copyWith(
      status: RouteSupportStatus.loading,
      errorMessage: '',
    ));

    final existingReviewId = args.reviewId;
    final NetworkResponse<RouteReviewDetail> response;
    if (existingReviewId != null) {
      response = await repo.fetchReview(existingReviewId);
    } else {
      // Checked here rather than only at the button that opens this page:
      // the doc is explicit that `is_paid_user` alone does not mean route
      // review is available (docs/mobile-chat-complete-api-websocket.md
      // §3.3), and this is the one place every create attempt - including a
      // retry - actually goes through.
      if (!await TollSession.ensureRouteReviewAvailable()) {
        emit(state.copyWith(status: RouteSupportStatus.notAvailable));
        return;
      }
      response = await repo.startReview(
        args.request!,
        idempotencyKey: _createIdempotencyKey,
      );
    }

    if (response.errorText.isNotEmpty || response.data == null) {
      emit(state.copyWith(
        status: RouteSupportStatus.failure,
        errorMessage: response.errorText,
      ));
      return;
    }

    emit(state.copyWith(
      status: RouteSupportStatus.ready,
      review: response.data,
    ));

    _retainReverb();
  }

  void _retainReverb() {
    if (_reverbRetained) return;
    _reverbRetained = true;
    _reverb.connect();
    _reverbMessageSub ??= _reverb.supportMessageCreated.listen(_onReverbMessage);
    _reverbReviewSub ??= _reverb.routeReviewUpdated.listen(_onReverbReviewUpdated);
  }

  /// A `support.message.created` frame - only relevant here when it belongs
  /// to this bloc's own review (docs/support-chat-api.md §2.1). The frame
  /// carries the message in full, but this screen replaces state wholesale
  /// rather than patching it in (§4.2's rule), so it is treated exactly like
  /// `mobile.route-review.updated`: a signal to re-fetch.
  void _onReverbMessage(Map<String, dynamic> data) {
    final reviewId = state.review?.id;
    if (reviewId == null || reviewId.isEmpty) return;
    final message = toMap(data['message']);
    if (toStr(message['route_review_id']) != reviewId) return;
    final messageId = toStr(message['id']);
    if (messageId.isEmpty || !_seenSocketMessageIds.add(messageId)) return;
    add(const RouteSupportRefreshed());
  }

  /// A `mobile.route-review.updated` frame (docs/support-chat-api.md §2.2).
  /// Deliberately reads nothing out of the payload beyond the ids needed to
  /// route and dedupe it - `mobile_result_endpoint` is not followed either,
  /// [RouteSupportRefreshed] already re-reads the same review by id.
  void _onReverbReviewUpdated(Map<String, dynamic> data) {
    final reviewId = state.review?.id;
    if (reviewId == null || reviewId.isEmpty) return;
    if (toStr(data['route_review_id']) != reviewId) return;
    final eventId = toStr(data['event_id']);
    if (eventId.isEmpty || !_seenReviewEventIds.add(eventId)) return;
    add(const RouteSupportRefreshed());
  }

  /// Silent re-read. Drops out while any mutation is in flight: those answer
  /// with the review too, and letting a concurrent GET land afterwards would
  /// briefly roll the screen back to the pre-mutation state.
  Future<void> _onRefreshed(
    RouteSupportRefreshed event,
    Emitter<RouteSupportState> emit,
  ) async {
    final reviewId = state.review?.id;
    if (reviewId == null || reviewId.isEmpty) return;
    if (state.sending ||
        state.confirmingRecommendationId.isNotEmpty ||
        state.driveStatus == RouteSupportDriveStatus.loading) {
      return;
    }

    final response = await repo.fetchReview(reviewId);
    // A failed refresh is deliberately invisible: the thread already on screen
    // stays correct, and the next tick tries again.
    if (response.errorText.isNotEmpty || response.data == null) return;

    emit(state.copyWith(review: response.data));
  }

  Future<void> _onMessageSent(
    RouteSupportMessageSent event,
    Emitter<RouteSupportState> emit,
  ) async {
    final text = event.text.trim();
    final reviewId = state.review?.id;
    if (text.isEmpty || state.sending || reviewId == null) return;

    emit(state.copyWith(sending: true, sendError: ''));

    final response = await repo.sendMessage(
      routeReviewId: reviewId,
      text: text,
    );
    if (response.errorText.isNotEmpty || response.data == null) {
      emit(state.copyWith(sending: false, sendError: response.errorText));
      return;
    }

    emit(state.copyWith(
      sending: false,
      review: response.data,
      status: RouteSupportStatus.ready,
    ));
  }

  Future<void> _onFuelConfirmed(
    RouteSupportFuelConfirmed event,
    Emitter<RouteSupportState> emit,
  ) async {
    final reviewId = state.review?.id;
    if (reviewId == null || state.confirmingRecommendationId.isNotEmpty) return;

    emit(state.copyWith(
      confirmingRecommendationId: event.recommendationId,
      confirmError: '',
    ));

    final response = await repo.confirmFuelRecommendation(
      routeReviewId: reviewId,
      recommendationId: event.recommendationId,
    );
    if (response.errorText.isNotEmpty || response.data == null) {
      emit(state.copyWith(
        confirmingRecommendationId: '',
        confirmError: response.errorText,
      ));
      return;
    }

    emit(state.copyWith(
      confirmingRecommendationId: '',
      review: response.data,
    ));
  }

  /// `POST mobile/navigation-sessions` for the approved route (§6).
  ///
  /// The review id goes with it so the backend can fold a confirmed fuel stop
  /// in as a waypoint - that is the only thing that makes a confirmed station
  /// actually affect the drive.
  Future<void> _onDrivePressed(
    RouteSupportDrivePressed event,
    Emitter<RouteSupportState> emit,
  ) async {
    final review = state.review;
    final approved = review?.approvedAlternative;
    if (review == null ||
        approved == null ||
        state.driveStatus == RouteSupportDriveStatus.loading) {
      return;
    }

    emit(state.copyWith(
      driveStatus: RouteSupportDriveStatus.loading,
      driveError: '',
    ));

    // Best-effort fresh fix - the session starts fine without one (the API
    // falls back to the route's origin), so a GPS miss must not block Drive.
    final position = await locationService.getCurrentLocation();

    final response = await tripsRepo.createNavigationSession(
      // The review carries the route request it belongs to; a create-mode
      // request is the same one and stands in if the field is somehow
      // absent. An open-existing review has no local fallback, but
      // `routeRequestId` should always be populated by then anyway.
      routeRequestId: review.routeRequestId.isNotEmpty
          ? review.routeRequestId
          : (args.request?.routeId ?? ''),
      routeAlternativeId: approved.id,
      routeReviewId: review.id,
      currentLocation: position == null
          ? null
          : TripCoordinate(lat: position.latitude, lng: position.longitude),
    );

    if (response.errorText.isNotEmpty || response.data == null) {
      emit(state.copyWith(
        driveStatus: RouteSupportDriveStatus.failure,
        driveError: response.errorText,
      ));
      return;
    }

    emit(state.copyWith(
      driveStatus: RouteSupportDriveStatus.idle,
      session: response.data,
      driveTick: state.driveTick + 1,
    ));
  }

  /// `POST .../cancel` (§9.4) - withdraws a still-`pending` request. Answers
  /// with the full review (`status: cancelled`), so this replaces state the
  /// same way every other mutation here does.
  Future<void> _onCancelled(
    RouteSupportCancelled event,
    Emitter<RouteSupportState> emit,
  ) async {
    final reviewId = state.review?.id;
    if (reviewId == null || state.cancelling || !state.canCancel) return;

    emit(state.copyWith(cancelling: true, cancelError: ''));

    final response = await repo.cancelReview(reviewId);
    if (response.errorText.isNotEmpty || response.data == null) {
      emit(state.copyWith(cancelling: false, cancelError: response.errorText));
      return;
    }

    emit(state.copyWith(cancelling: false, review: response.data));
  }

  @override
  Future<void> close() {
    _reverbMessageSub?.cancel();
    _reverbReviewSub?.cancel();
    if (_reverbRetained) {
      _reverb.disconnect();
      _reverbRetained = false;
    }
    return super.close();
  }
}

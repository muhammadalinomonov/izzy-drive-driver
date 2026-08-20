import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/core/location_service.dart';
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
/// the whole [RouteSupportRequest] as a runtime argument, which is more than
/// `@factoryParam` carries comfortably - same reason `RouteOverviewBloc` is
/// built there. Its dependencies still come from the container.
class RouteSupportBloc extends Bloc<RouteSupportEvent, RouteSupportState> {
  final RouteSupportRepo repo;

  /// Only for Drive: the navigation session lives on the trips repo, since it
  /// is the same session the route overview's Start button opens.
  final TripsRepo tripsRepo;

  final LocationService locationService;

  /// The route the conversation is about. Fixed for the life of the page, and
  /// the only source of the endpoint address labels - the route API returns
  /// coordinates and no address text at all
  /// (docs/mobile-chat-route-fuel-drive.md §7).
  final RouteSupportRequest request;

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
    required this.request,
  }) : super(const RouteSupportState()) {
    on<RouteSupportStarted>(_onStarted);
    on<RouteSupportRefreshed>(_onRefreshed);
    on<RouteSupportMessageSent>(_onMessageSent);
    on<RouteSupportFuelConfirmed>(_onFuelConfirmed);
    on<RouteSupportDrivePressed>(_onDrivePressed);
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

    emit(state.copyWith(
      status: RouteSupportStatus.ready,
      review: response.data,
    ));
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
      // The review carries the route request it belongs to; the request the
      // page opened with is the same one, and stands in if the field is absent.
      routeRequestId: review.routeRequestId.isNotEmpty
          ? review.routeRequestId
          : request.routeId,
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
}

part of 'route_support_bloc.dart';

enum RouteSupportStatus { initial, loading, ready, failure }

/// Drive's own status, kept apart from [RouteSupportStatus]: a failed session
/// start leaves a perfectly readable thread behind it.
enum RouteSupportDriveStatus { idle, loading, failure }

class RouteSupportState extends Equatable {
  final RouteSupportStatus status;

  /// The review as last read from the server - the screen's source of truth
  /// for the card, the decision, the fuel stops and whether Drive shows.
  /// Null only before the first successful read.
  final RouteReviewDetail? review;

  final String errorMessage;

  /// A follow-up is in flight. Keeps the composer from posting twice.
  final bool sending;

  /// Why the last send failed. Surfaced as a snack bar, not as a page state -
  /// the thread itself is still readable.
  final String sendError;

  /// Recommendation currently being confirmed, so only that row shows a
  /// spinner rather than the whole list going inert.
  final String confirmingRecommendationId;

  /// Why the last fuel confirm failed. Snack bar, same reasoning as
  /// [sendError].
  final String confirmError;

  final RouteSupportDriveStatus driveStatus;
  final String driveError;

  /// The session Drive opened. Handed to driving mode by the page.
  final NavigationSessionModel? session;

  /// Bumped on every successful start so the page navigates once per press,
  /// even if two presses produce the same session object.
  final int driveTick;

  const RouteSupportState({
    this.status = RouteSupportStatus.initial,
    this.review,
    this.errorMessage = '',
    this.sending = false,
    this.sendError = '',
    this.confirmingRecommendationId = '',
    this.confirmError = '',
    this.driveStatus = RouteSupportDriveStatus.idle,
    this.driveError = '',
    this.session,
    this.driveTick = 0,
  });

  List<SupportChatMessage> get messages => review?.messages ?? const [];

  /// A loaded thread with nothing in it - support has not written back and the
  /// driver has not said anything yet.
  bool get isEmpty =>
      status == RouteSupportStatus.ready && messages.isEmpty;

  /// The review is decided against or closed, so there is nothing left to
  /// write - posting would answer 409 MOBILE_ROUTE_REVIEW_CLOSED.
  bool get isClosed => review?.status.isClosed ?? false;

  RouteSupportState copyWith({
    RouteSupportStatus? status,
    RouteReviewDetail? review,
    String? errorMessage,
    bool? sending,
    String? sendError,
    String? confirmingRecommendationId,
    String? confirmError,
    RouteSupportDriveStatus? driveStatus,
    String? driveError,
    NavigationSessionModel? session,
    int? driveTick,
  }) {
    return RouteSupportState(
      status: status ?? this.status,
      review: review ?? this.review,
      errorMessage: errorMessage ?? this.errorMessage,
      sending: sending ?? this.sending,
      sendError: sendError ?? this.sendError,
      confirmingRecommendationId:
          confirmingRecommendationId ?? this.confirmingRecommendationId,
      confirmError: confirmError ?? this.confirmError,
      driveStatus: driveStatus ?? this.driveStatus,
      driveError: driveError ?? this.driveError,
      session: session ?? this.session,
      driveTick: driveTick ?? this.driveTick,
    );
  }

  @override
  List<Object?> get props => [
        status,
        review,
        errorMessage,
        sending,
        sendError,
        confirmingRecommendationId,
        confirmError,
        driveStatus,
        driveError,
        session,
        driveTick,
      ];
}

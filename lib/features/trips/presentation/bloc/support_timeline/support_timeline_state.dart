part of 'support_timeline_bloc.dart';

enum SupportTimelineStatus {
  initial,
  loading,
  ready,
  failure,

  /// Reached the page without the Premium entitlement - see
  /// `SupportChatBloc`'s old identical guard, which this bloc replaces.
  /// Distinct from [failure]: nothing was tried, so there is no retry button.
  restricted,
}

class SupportTimelineState extends Equatable {
  final SupportTimelineStatus status;

  /// Oldest-first, for a top-to-bottom thread read - derived from the bloc's
  /// keyed store, not from response order (see `SupportTimelineBloc._feed`).
  final List<SupportTimelineItem> items;

  final String errorMessage;

  /// A send is in flight. Keeps the composer from posting twice.
  final bool sending;

  /// Why the last send failed. Surfaced as a snack bar, not a page state -
  /// the feed itself is still readable.
  final String sendError;

  /// Highest page number pulled in so far. Page 1 is the newest slice; older
  /// history is higher-numbered (§6.3's newest-first ordering).
  final int loadedPage;

  /// `pagination.last_page` as of the most recent response.
  final int lastPage;

  /// An older page is in flight - shows a spinner at the top of the feed and
  /// keeps the scroll trigger from firing again.
  final bool loadingMore;

  const SupportTimelineState({
    this.status = SupportTimelineStatus.initial,
    this.items = const [],
    this.errorMessage = '',
    this.sending = false,
    this.sendError = '',
    this.loadedPage = 1,
    this.lastPage = 1,
    this.loadingMore = false,
  });

  /// A loaded feed with nothing in it - neither side has written, and no
  /// review has been requested yet.
  bool get isEmpty =>
      status == SupportTimelineStatus.ready && items.isEmpty;

  /// There is older history left to pull.
  bool get hasMore => loadedPage < lastPage;

  SupportTimelineState copyWith({
    SupportTimelineStatus? status,
    List<SupportTimelineItem>? items,
    String? errorMessage,
    bool? sending,
    String? sendError,
    int? loadedPage,
    int? lastPage,
    bool? loadingMore,
  }) {
    return SupportTimelineState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
      sending: sending ?? this.sending,
      sendError: sendError ?? this.sendError,
      loadedPage: loadedPage ?? this.loadedPage,
      lastPage: lastPage ?? this.lastPage,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        errorMessage,
        sending,
        sendError,
        loadedPage,
        lastPage,
        loadingMore,
      ];
}

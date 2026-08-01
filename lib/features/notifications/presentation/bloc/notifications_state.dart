part of 'notifications_bloc.dart';

enum NotificationsListStatus { initial, loading, success, failure }

class NotificationsState extends Equatable {
  final NotificationsListStatus listStatus;
  final NotificationsListStatus loadMoreStatus;
  final List<NotificationModel> items;
  final String? nextUrl;
  final int unreadCount;
  final String errorMessage;

  const NotificationsState({
    this.listStatus = NotificationsListStatus.initial,
    this.loadMoreStatus = NotificationsListStatus.initial,
    this.items = const [],
    this.nextUrl,
    this.unreadCount = 0,
    this.errorMessage = '',
  });

  bool get hasMore => nextUrl != null && nextUrl!.isNotEmpty;

  static const _sentinel = Object();

  NotificationsState copyWith({
    NotificationsListStatus? listStatus,
    NotificationsListStatus? loadMoreStatus,
    List<NotificationModel>? items,
    Object? nextUrl = _sentinel,
    int? unreadCount,
    String? errorMessage,
  }) {
    return NotificationsState(
      listStatus: listStatus ?? this.listStatus,
      loadMoreStatus: loadMoreStatus ?? this.loadMoreStatus,
      items: items ?? this.items,
      nextUrl: identical(nextUrl, _sentinel) ? this.nextUrl : nextUrl as String?,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        listStatus,
        loadMoreStatus,
        items,
        nextUrl,
        unreadCount,
        errorMessage,
      ];
}

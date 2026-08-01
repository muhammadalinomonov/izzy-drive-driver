part of 'notifications_bloc.dart';

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class NotificationsLoaded extends NotificationsEvent {
  const NotificationsLoaded();
}

class NotificationsRefreshed extends NotificationsEvent {
  const NotificationsRefreshed();
}

class NotificationsLoadMore extends NotificationsEvent {
  const NotificationsLoadMore();
}

class NotificationMarkRead extends NotificationsEvent {
  final int id;

  const NotificationMarkRead(this.id);

  @override
  List<Object?> get props => [id];
}

class NotificationsMarkAllRead extends NotificationsEvent {
  const NotificationsMarkAllRead();
}

class UnreadCountRequested extends NotificationsEvent {
  const UnreadCountRequested();
}

class NotificationReceivedFromPush extends NotificationsEvent {
  final int? notificationId;

  const NotificationReceivedFromPush({this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

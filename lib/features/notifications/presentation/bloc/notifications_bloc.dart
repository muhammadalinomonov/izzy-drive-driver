import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/core/utils/notifications.dart';
import 'package:taxi_app/features/notifications/data/model/notification_model.dart';
import 'package:taxi_app/features/notifications/domain/repo/notifications_repo.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRepo repo;
  late final VoidCallback _pushListener;

  NotificationsBloc({required this.repo}) : super(const NotificationsState()) {
    on<NotificationsLoaded>(_onLoad);
    on<NotificationsRefreshed>(_onRefresh);
    on<NotificationsLoadMore>(_onLoadMore);
    on<NotificationMarkRead>(_onMarkRead);
    on<NotificationsMarkAllRead>(_onMarkAllRead);
    on<UnreadCountRequested>(_onUnreadCount);
    on<NotificationReceivedFromPush>(_onPushReceived);

    _pushListener = () => add(const NotificationReceivedFromPush());
    PushNotifications.notificationPing.addListener(_pushListener);
  }

  @override
  Future<void> close() {
    PushNotifications.notificationPing.removeListener(_pushListener);
    return super.close();
  }

  Future<void> _onLoad(
    NotificationsLoaded event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state.listStatus == NotificationsListStatus.loading) return;
    emit(state.copyWith(
      listStatus: NotificationsListStatus.loading,
      errorMessage: '',
    ));
    final response = await repo.fetchPage(page: 1);
    if (response.errorText.isEmpty && response.data != null) {
      final page = response.data!;
      final unread = page.items.where((n) => !n.isRead).length;
      emit(state.copyWith(
        listStatus: NotificationsListStatus.success,
        items: page.items,
        nextUrl: page.next,
        unreadCount: state.unreadCount == 0 && page.currentPage == 1 ? unread : state.unreadCount,
      ));
      // Refresh authoritative unread count from server.
      add(const UnreadCountRequested());
    } else {
      emit(state.copyWith(
        listStatus: NotificationsListStatus.failure,
        errorMessage: response.errorText,
      ));
    }
  }

  Future<void> _onRefresh(
    NotificationsRefreshed event,
    Emitter<NotificationsState> emit,
  ) async {
    // silent - preserve current list while reloading, don't flash shimmer.
    final response = await repo.fetchPage(page: 1);
    if (response.errorText.isEmpty && response.data != null) {
      final page = response.data!;
      emit(state.copyWith(
        listStatus: NotificationsListStatus.success,
        items: page.items,
        nextUrl: page.next,
        errorMessage: '',
      ));
      add(const UnreadCountRequested());
    } else {
      emit(state.copyWith(errorMessage: response.errorText));
    }
  }

  Future<void> _onLoadMore(
    NotificationsLoadMore event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state.loadMoreStatus == NotificationsListStatus.loading) return;
    final next = state.nextUrl;
    if (next == null || next.isEmpty) return;
    emit(state.copyWith(loadMoreStatus: NotificationsListStatus.loading));
    final response = await repo.fetchPage(absoluteUrl: next);
    if (response.errorText.isEmpty && response.data != null) {
      final page = response.data!;
      emit(state.copyWith(
        loadMoreStatus: NotificationsListStatus.success,
        items: [...state.items, ...page.items],
        nextUrl: page.next,
      ));
    } else {
      emit(state.copyWith(
        loadMoreStatus: NotificationsListStatus.failure,
        errorMessage: response.errorText,
      ));
    }
  }

  Future<void> _onMarkRead(
    NotificationMarkRead event,
    Emitter<NotificationsState> emit,
  ) async {
    // Optimistic update - local item read flag flips immediately.
    final idx = state.items.indexWhere((n) => n.id == event.id);
    if (idx < 0) return;
    final item = state.items[idx];
    if (item.isRead) return;
    final updated = [...state.items];
    updated[idx] = item.copyWith(isRead: true);
    emit(state.copyWith(
      items: updated,
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    ));
    await repo.markRead(event.id);
  }

  Future<void> _onMarkAllRead(
    NotificationsMarkAllRead event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state.unreadCount == 0) return;
    final updated = state.items.map((n) => n.copyWith(isRead: true)).toList();
    emit(state.copyWith(items: updated, unreadCount: 0));
    await repo.markAllRead();
  }

  Future<void> _onUnreadCount(
    UnreadCountRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final response = await repo.unreadCount();
    if (response.errorText.isEmpty && response.data != null) {
      emit(state.copyWith(unreadCount: response.data!));
    }
  }

  Future<void> _onPushReceived(
    NotificationReceivedFromPush event,
    Emitter<NotificationsState> emit,
  ) async {
    // FCM payload kelganda - listni qaytadan yuklaymiz va counterni yangilaymiz.
    add(const NotificationsRefreshed());
    add(const UnreadCountRequested());
  }
}

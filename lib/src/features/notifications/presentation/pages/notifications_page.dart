import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:taxi_app/src/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:taxi_app/src/routes/pages.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // The bloc owner constructs us with an initial Load already dispatched.
    final bloc = context.read<NotificationsBloc>();
    if (bloc.state.listStatus == NotificationsListStatus.initial) {
      bloc.add(const NotificationsLoaded());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 120;
    if (_scrollController.position.pixels >= threshold) {
      final state = context.read<NotificationsBloc>().state;
      if (state.hasMore && state.loadMoreStatus != NotificationsListStatus.loading) {
        context.read<NotificationsBloc>().add(const NotificationsLoadMore());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: SvgPicture.asset(AppIcons.back, width: 20, height: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'notifications.title'.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            buildWhen: (a, b) => a.unreadCount != b.unreadCount,
            builder: (context, state) {
              if (state.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => context.read<NotificationsBloc>().add(const NotificationsMarkAllRead()),
                child: Text(
                  'notifications.markAllRead'.tr(),
                  style: TextStyle(color: AppColor.kPrimaryColor, fontSize: 13),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          if (state.listStatus == NotificationsListStatus.loading && state.items.isEmpty) {
            return const _NotificationsSkeleton();
          }
          if (state.listStatus == NotificationsListStatus.failure && state.items.isEmpty) {
            return _ErrorView(
              message: state.errorMessage,
              onRetry: () => context.read<NotificationsBloc>().add(const NotificationsLoaded()),
            );
          }
          if (state.items.isEmpty) {
            return _EmptyView(
              onRefresh: () async {
                context.read<NotificationsBloc>().add(const NotificationsRefreshed());
                await Future.delayed(const Duration(milliseconds: 350));
              },
            );
          }
          return RefreshIndicator.adaptive(
            onRefresh: () async {
              context.read<NotificationsBloc>().add(const NotificationsRefreshed());
              await Future.delayed(const Duration(milliseconds: 350));
            },
            child: ListView.separated(
              separatorBuilder: (context, index) => Divider(color:  AppColor.grey2, indent: 64, height: 1),
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: state.items.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  );
                }
                final item = state.items[index];
                return NotificationTile(
                  notification: item,
                  onTap: () {
                    final bloc = context.read<NotificationsBloc>();
                    if (!item.isRead) {
                      bloc.add(NotificationMarkRead(item.id));
                    }
                    context.push(Pages.notificationDetail, extra: {'id': item.id});
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEFF3F6),
      highlightColor: const Color(0xFFF7F9FB),
      period: const Duration(milliseconds: 1400),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 8,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3F6),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      color: const Color(0xFFEFF3F6),
                    ),
                    const SizedBox(height: 6),
                    Container(height: 12, width: 220, color: const Color(0xFFEFF3F6)),
                    const SizedBox(height: 6),
                    Container(height: 10, width: 80, color: const Color(0xFFEFF3F6)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height / 4),
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColor.lightBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      AppIcons.bell,
                      width: 28,
                      height: 28,
                      colorFilter: ColorFilter.mode(AppColor.kPrimaryColor, BlendMode.srcIn),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'notifications.emptyTitle'.tr(),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'notifications.emptySubtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColor.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: AppColor.darkGrey),
            const SizedBox(height: 12),
            Text(
              message.isEmpty ? 'common.somethingWentWrong'.tr() : message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColor.grey),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

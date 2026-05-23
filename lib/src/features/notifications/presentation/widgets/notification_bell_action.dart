import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:taxi_app/src/routes/pages.dart';

/// AppBar uchun bell tugmasi - unread count'ga qarab badge ko'rsatadi.
/// MainScreen ichidagi NotificationsBloc'dan o'qiydi; tap qilinganda
/// /notifications page ochiladi va u yopilganda badge yangilanadi.
class NotificationBellAction extends StatelessWidget {
  const NotificationBellAction({super.key, this.iconColor});

  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      buildWhen: (a, b) => a.unreadCount != b.unreadCount,
      builder: (context, state) {
        final count = state.unreadCount;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: IconButton(
            tooltip: 'Notifications',
            onPressed: () async {
              await context.push(Pages.notifications);
              if (!context.mounted) return;
              context.read<NotificationsBloc>().add(const UnreadCountRequested());
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                SvgPicture.asset(
                  AppIcons.bell,
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    iconColor ?? AppColor.black,
                    BlendMode.srcIn,
                  ),
                ),
                if (count > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColor.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Center(
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

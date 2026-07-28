import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/features/notifications/data/model/notification_model.dart';
import 'package:taxi_app/src/features/notifications/domain/repo/notifications_repo.dart';

class NotificationDetailPage extends StatefulWidget {
  const NotificationDetailPage({super.key, required this.id, required this.repo});

  final int id;
  final NotificationsRepo repo;

  @override
  State<NotificationDetailPage> createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends State<NotificationDetailPage> {
  late Future<NetworkResponse<NotificationModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repo.getDetail(widget.id);
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
          'notifications.detailTitle'.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: FutureBuilder<NetworkResponse<NotificationModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _DetailSkeleton();
          }
          final response = snapshot.data;
          if (response == null || response.errorText.isNotEmpty || response.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  response?.errorText.isNotEmpty == true
                      ? response!.errorText
                      : 'common.somethingWentWrong'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColor.grey),
                ),
              ),
            );
          }
          final n = response.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (n.imageUrl != null && n.imageUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      n.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  n.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(n.createdAt),
                  style: TextStyle(fontSize: 11, color: AppColor.darkGrey),
                ),
                const SizedBox(height: 16),
                Text(
                  n.body,
                  style: TextStyle(fontSize: 15, color: AppColor.black, height: 1.5),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _two(int v) => v.toString().padLeft(2, '0');

String _formatTime(DateTime? dt) {
  if (dt == null) return '';
  final local = dt.toLocal();
  return '${_two(local.day)}.${_two(local.month)}.${local.year}, ${_two(local.hour)}:${_two(local.minute)}';
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEFF3F6),
      highlightColor: const Color(0xFFF7F9FB),
      period: const Duration(milliseconds: 1400),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 22, width: double.infinity, color: const Color(0xFFEFF3F6)),
            const SizedBox(height: 12),
            Container(height: 14, width: 120, color: const Color(0xFFEFF3F6)),
            const SizedBox(height: 24),
            Container(height: 14, width: double.infinity, color: const Color(0xFFEFF3F6)),
            const SizedBox(height: 8),
            Container(height: 14, width: double.infinity, color: const Color(0xFFEFF3F6)),
            const SizedBox(height: 8),
            Container(height: 14, width: 240, color: const Color(0xFFEFF3F6)),
          ],
        ),
      ),
    );
  }
}

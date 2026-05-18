import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';
import 'package:taxi_app/src/core/utils/my_functions.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_button.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_image.dart';
import 'package:taxi_app/src/features/master/presentation/bloc/master_bloc.dart';
import 'package:taxi_app/src/features/master/presentation/screens/all_reviews_screen.dart';
import 'package:taxi_app/src/features/master/presentation/widgets/review_item.dart';

class MasterDetailSheet extends StatefulWidget {
  const MasterDetailSheet({super.key, required this.id});

  final int id;

  @override
  State<MasterDetailSheet> createState() => _MasterDetailSheetState();
}

class _MasterDetailSheetState extends State<MasterDetailSheet> {
  @override
  void initState() {
    super.initState();

    context.read<MasterBloc>().add(GetMasterDetail(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.sizeOf.width,
      constraints: BoxConstraints(maxHeight: context.sizeOf.height * .9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        color: AppColor.lightBlue,
      ),
      child: BlocBuilder<MasterBloc, MasterState>(
        builder: (context, state) {
          final master = state.masterDetail;
          // Performance — successOrdersCount / allOrdersCount %.
          final allOrders = master.allOrdersCount;
          final successOrders = master.successOrdersCount;
          final performance = allOrders > 0
              ? (successOrders / allOrders * 100).round()
              : 0;
          final firstReview =
              state.masterReviews.isNotEmpty ? state.masterReviews.first : null;
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1) Header — drag handle + avatar + name + register
                      // date + stats. Figma'da drag handle aynan shu oq
                      // kartochka ichida joylashgan; bottom-sheet bilan
                      // kartochka orasida padding yo'q.
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppColor.white,
                        ),
                        child: Column(
                          children: [
                            // Drag handle (Figma — kartochka ichida)
                            Container(
                              height: 4,
                              width: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: AppColor.grey2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AvatarImage(
                              imageUrl: master.photo ?? '',
                              name: master.fullName ?? '',
                              size: 87,
                            ),
                            const SizedBox(height: 13),
                            Text(
                              master.fullName ?? '',
                              style: context.textTheme.bodyLarge!.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Registred data ${MyFunctions.formatDateWithRelative(master.createdAt)}',
                              style: context.textTheme.bodyMedium!.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: AppColor.grey,
                              ),
                            ),
                            const SizedBox(height: 23),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _StatColumn(
                                  label: 'All orders',
                                  value: allOrders.toString(),
                                ),
                                _StatColumn(
                                  label: 'Success',
                                  value: successOrders.toString(),
                                ),
                                _StatColumn(
                                  label: 'Performance',
                                  value: '$performance%',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // 2) Reviews — 1 preview + "All comments" CTA
                      if (state.masterReviewStatus.isSuccess &&
                          firstReview != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AppColor.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reviews and ratings'.toUpperCase(),
                                style: context.textTheme.bodyLarge!.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.darkGrey,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ReviewItem(
                                rating: firstReview.stars,
                                review: firstReview.comment,
                                date: firstReview.createdAt,
                                avatar: firstReview.driverAvatar,
                                name: firstReview.driverName,
                              ),
                              if (state.masterReviews.length > 1) ...[
                                const SizedBox(height: 8),
                                Divider(
                                  height: 1,
                                  color: AppColor.grey2,
                                ),
                                const SizedBox(height: 4),
                                Center(
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => AllReviewsScreen(
                                            reviews: state.masterReviews,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'ALL COMMENTS',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColor.kPrimaryColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      // 3) "Call the master" — online status + distance
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppColor.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CALL THE MASTER',
                              style: context.textTheme.bodyLarge!.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColor.darkGrey,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _MasterInfoRow(
                              label: 'Master status',
                              value: _localizeStatus(master.status),
                              valueColor: _statusColor(
                                master.status,
                                context,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Divider(height: 1, color: AppColor.grey2),
                            const SizedBox(height: 12),
                            _MasterInfoRow(
                              label: 'Distance from you',
                              // Backend ikkita field'da masofa qaytaradi:
                              //  - `distance` (Haversine, serializer'dan)
                              //  - `map.distance_km` (real route)
                              // Birinchisi 0 bo'lsa ikkinchisiga o'tamiz.
                              // Mexanikda koord bor lekin masofa 0 bo'lsa
                              // (driver-mechanic bir xil joyda — masalan
                              // iOS Simulator default location) — "Nearby".
                              value: _formatDistance(
                                master.distance > 0
                                    ? master.distance
                                    : master.map.distanceKm,
                                hasCoords: master.latitude != 0 ||
                                    master.longitude != 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              // Bottom button — back/dismiss (foydalanuvchi so'roviga ko'ra
              // "Chatni ochish" emas, ortga qaytish tugmasi).
              CommonButton(
                text: 'Back',
                color: AppColor.kPrimaryColor,
                textColor: AppColor.white,
                margin: EdgeInsets.only(
                  bottom: context.padding.bottom + 8,
                  right: 16,
                  left: 16,
                  top: 8,
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDistance(double km, {required bool hasCoords}) {
    // Mexanikda manzil ham yo'q — vizual "—".
    if (!hasCoords) return '—';
    // Manzil bor lekin masofa nol yoki minus — driver mexanik bilan
    // bir xil nuqtada (iOS Simulator default location holatida tipik).
    if (km <= 0) return 'Nearby';
    if (km < 1) {
      final meters = (km * 1000).round();
      return '$meters m away';
    }
    return '${km.toStringAsFixed(1)} km away';
  }

  String _localizeStatus(String? status) {
    if (status == null || status.isEmpty) return 'Offline';
    final normalized = status.toLowerCase();
    if (normalized == 'online') return 'Online';
    if (normalized == 'offline') return 'Offline';
    if (normalized == 'busy') return 'Busy';
    return status;
  }

  Color _statusColor(String? status, BuildContext context) {
    final normalized = (status ?? '').toLowerCase();
    if (normalized == 'online') return AppColor.kPrimaryColor;
    if (normalized == 'busy') return AppColor.red;
    return AppColor.grey;
  }
}

class _MasterInfoRow extends StatelessWidget {
  const _MasterInfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.bodyMedium!.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColor.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: context.textTheme.bodyLarge!.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColor.black,
          ),
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.textTheme.bodyMedium!.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColor.darkGrey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: context.textTheme.bodyLarge!.copyWith(fontSize: 22, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

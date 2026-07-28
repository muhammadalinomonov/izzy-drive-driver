import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';
import 'package:taxi_app/src/core/utils/my_functions.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_button.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_image.dart';
import 'package:taxi_app/src/features/master/presentation/bloc/master_bloc.dart';
import 'package:taxi_app/src/features/master/presentation/screens/all_reviews_screen.dart';
import 'package:taxi_app/src/features/master/presentation/widgets/master_status_helpers.dart';
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
    // DraggableScrollableSheet lets the user drag the entire sheet down by
    // pulling on the content (not just the handle). When the inner scroll is
    // at top, the gesture is captured by the sheet and shrinks it. Once it
    // hits minChildSize the modal barrier-tap or the Back button dismiss.
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        width: context.sizeOf.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          color: AppColor.lightBlue,
        ),
        child: BlocBuilder<MasterBloc, MasterState>(
          builder: (context, state) {
            final isLoading = state.getMasterDetailStatus.isInProgress ||
                state.getMasterDetailStatus.isInitial;
            if (isLoading) {
              return _MasterDetailSkeleton(scrollController: scrollController);
            }
            final master = state.masterDetail;
            // Performance: backend is the source of truth (formula can change
            // server-side without an app release). Fall back to the local
            // success/all ratio only while backend rollout is in progress.
            final allOrders = master.allOrdersCount;
            final successOrders = master.successOrdersCount;
            final performance = master.performance ??
                (allOrders > 0 ? (successOrders / allOrders * 100).round() : 0);
            final firstReview =
                state.masterReviews.isNotEmpty ? state.masterReviews.first : null;
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1) Header - drag handle + avatar + name + register
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
                            // Drag handle (Figma - kartochka ichida)
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
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Registred data ${MyFunctions.formatDateWithRelative(master.createdAt)}',
                              style: context.textTheme.bodyMedium!.copyWith(
                                fontSize: 11,
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
                      // 2) Reviews - 1 preview + "All comments" CTA
                      if (state.masterReviewStatus.isSuccess &&
                          firstReview != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
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
                                tag: firstReview.tag,
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
                                        fontSize: 13,
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
                      // 3) "Call the master" - online status + distance
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
                              value: masterStatusLabel(master.status),
                              valueColor: masterStatusColor(master.status),
                            ),
                            const SizedBox(height: 10),
                            Divider(height: 1, color: AppColor.grey2),
                            const SizedBox(height: 12),
                            _MasterInfoRow(
                              label: 'Distance from you',
                              value: masterDistanceLabel(master),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              // Bottom button - back/dismiss (foydalanuvchi so'roviga ko'ra
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
      ),
    );
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
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColor.darkGrey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: context.textTheme.bodyLarge!.copyWith(fontSize: 20, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _MasterDetailSkeleton extends StatelessWidget {
  const _MasterDetailSkeleton({this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            child: Shimmer.fromColors(
              baseColor: const Color(0xFFE9EDF1),
              highlightColor: const Color(0xFFF7F9FB),
              period: const Duration(milliseconds: 1400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColor.white,
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 4,
                          width: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: AppColor.grey2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _SkeletonBox(width: 87, height: 87, radius: 87),
                        const SizedBox(height: 13),
                        const _SkeletonBox(width: 160, height: 16, radius: 6),
                        const SizedBox(height: 8),
                        const _SkeletonBox(width: 200, height: 11, radius: 6),
                        const SizedBox(height: 23),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            _SkeletonStat(),
                            _SkeletonStat(),
                            _SkeletonStat(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColor.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _SkeletonBox(width: 120, height: 12, radius: 6),
                        SizedBox(height: 16),
                        _SkeletonBox(width: 100, height: 12, radius: 6),
                        SizedBox(height: 6),
                        _SkeletonBox(width: 140, height: 16, radius: 6),
                        SizedBox(height: 16),
                        _SkeletonBox(width: 130, height: 12, radius: 6),
                        SizedBox(height: 6),
                        _SkeletonBox(width: 150, height: 16, radius: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            bottom: context.padding.bottom + 8,
            right: 16,
            left: 16,
            top: 8,
          ),
          child: Shimmer.fromColors(
            baseColor: const Color(0xFFE9EDF1),
            highlightColor: const Color(0xFFF7F9FB),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.width, required this.height, this.radius = 4});

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SkeletonStat extends StatelessWidget {
  const _SkeletonStat();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _SkeletonBox(width: 60, height: 12, radius: 6),
        SizedBox(height: 8),
        _SkeletonBox(width: 40, height: 22, radius: 6),
      ],
    );
  }
}

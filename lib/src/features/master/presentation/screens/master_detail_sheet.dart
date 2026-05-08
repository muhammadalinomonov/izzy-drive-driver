import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';
import 'package:taxi_app/src/core/utils/my_functions.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_button.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_image.dart';
import 'package:taxi_app/src/features/master/presentation/bloc/master_bloc.dart';
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
          return Column(
            children: [
              Container(
                width: context.sizeOf.width,
                padding: EdgeInsets.only(top: 12, bottom: 18, right: 50, left: 50),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24), bottom: Radius.circular(12)),
                  color: AppColor.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 4,
                      width: 50,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: AppColor.grey2),
                    ),
                    SizedBox(height: 34),
                    Container(
                      height: 87,
                      width: 87,
                      decoration: BoxDecoration(shape: BoxShape.circle),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(87),
                        child: CommonNetworkImage(imageUrl: state.masterDetail.photo ?? ''),
                      ),
                    ),
                    SizedBox(height: 13),
                    Text(
                      state.masterDetail.fullName ?? '',
                      style: context.textTheme.bodyLarge!.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Registred data ${MyFunctions.formatDateTime(state.masterDetail.createdAt)}',
                      style: context.textTheme.bodyMedium!.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColor.grey,
                      ),
                    ),
                    SizedBox(height: 23),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'All orders',
                              style: context.textTheme.bodyMedium!.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColor.darkGrey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              state.masterDetail.allOrdersCount.toString(),
                              style: context.textTheme.bodyLarge!.copyWith(fontSize: 22, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Success',
                              style: context.textTheme.bodyMedium!.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColor.darkGrey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              state.masterDetail.successOrdersCount.toString(),
                              style: context.textTheme.bodyLarge!.copyWith(fontSize: 22, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Rating',
                              style: context.textTheme.bodyMedium!.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColor.darkGrey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              state.masterDetail.rating.toString(),
                              style: context.textTheme.bodyLarge!.copyWith(fontSize: 22, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (state.masterReviewStatus.isSuccess && state.masterReviews.isNotEmpty)
                Expanded(
                  child: Container(
                    width: context.sizeOf.width,
                    padding: EdgeInsets.symmetric(vertical: 19, horizontal: 12),
                    margin: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColor.white),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reviews and ratings'.toUpperCase(),
                          style: context.textTheme.bodyLarge!.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColor.darkGrey,
                          ),
                        ),
                        SizedBox(height: 18),
                        Expanded(
                          child: ListView.separated(
                            itemBuilder: (context, index) {
                              final review = state.masterReviews[index];
                              return ReviewItem(
                                rating: review.stars,
                                review: review.comment,
                                date: review.createdAt,
                                avatar: review.driverAvatar,
                                name: review.driverName,
                              );
                            },
                            separatorBuilder: (context, index) => SizedBox(height: 8),
                            itemCount: state.masterReviews.length,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Spacer(),
              CommonButton(
                text: 'Exit',
                color: AppColor.grey2,
                textColor: AppColor.black,
                margin: EdgeInsets.only(bottom: context.padding.bottom, right: 16, left: 16, top: 8),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

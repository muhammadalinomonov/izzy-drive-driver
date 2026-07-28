import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';
import 'package:taxi_app/src/features/profile/presentation/widgets/info_item.dart';

class OrderInformationWidget extends StatelessWidget {
  const OrderInformationWidget({super.key, required this.createdAt, required this.workDuration, required this.address});

  final String createdAt;
  final String workDuration;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.sizeOf.width,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColor.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order details',
            style: context.textTheme.bodyMedium!.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          InfoItem(title: 'Order placed', info: createdAt),
          Divider(height: 25, thickness: 1, color: AppColor.grey),
          InfoItem(title: 'Time spent', info: workDuration),
          Divider(height: 25, thickness: 1, color: AppColor.grey),
          InfoItem(title: 'Destination', info: address),
          Divider(height: 25, thickness: 1, color: AppColor.grey),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment type',
                style: context.textTheme.bodySmall!.copyWith(
                  fontSize: 11,
                  color: AppColor.grey2,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.payments_outlined, size: 18, color: AppColor.kPrimaryColor),
                  SizedBox(width: 4),
                  Text(
                    'Cash'.tr(),
                    style: context.textTheme.bodySmall!.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  Spacer(),
                  // SvgPicture.asset(AppIcons.circularCheck, width: 20, height: 20),
                  SizedBox(width: 4),
                  // Text(
                  //   'To’landi',
                  //   style: context.textTheme.bodySmall!.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                  // ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

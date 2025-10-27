import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
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
            'Buyurtma ma’lumotlari',
            style: context.textTheme.bodyMedium!.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          InfoItem(title: 'Buyurtma berildi', info: createdAt),
          Divider(height: 25, thickness: 1, color: AppColor.grey),
          InfoItem(title: 'Sarflangan vaqt', info: workDuration),
          Divider(height: 25, thickness: 1, color: AppColor.grey),
          InfoItem(title: 'Qayerga', info: address),
          Divider(height: 25, thickness: 1, color: AppColor.grey),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To’lov turi',
                style: context.textTheme.bodySmall!.copyWith(
                  fontSize: 12,
                  color: AppColor.grey2,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  SvgPicture.asset(AppIcons.apple, width: 20),
                  SizedBox(width: 4),
                  Text(
                    'Apple Pay',
                    style: context.textTheme.bodySmall!.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
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

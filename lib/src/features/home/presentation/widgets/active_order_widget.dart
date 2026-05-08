import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_images.dart';
import 'package:taxi_app/src/core/enums/order_enums.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';

class ActiveOrderWidget extends StatelessWidget {
  const ActiveOrderWidget({super.key, required this.orderId, required this.status});

  final int orderId;
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        //number sign
        Text(
          'Active order N $orderId',
          style: context.textTheme.bodyLarge!.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColor.kPrimaryColor.withValues(alpha: 0.1),
          ),
          child: Row(
            children: [
              Image.asset(AppImages.key, width: 44, height: 44),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  status.orderDescription,
                  style: context.textTheme.bodyLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

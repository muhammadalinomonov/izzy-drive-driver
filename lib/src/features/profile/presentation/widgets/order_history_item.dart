import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_images.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';

class OrderHistoryItem extends StatelessWidget {
  const OrderHistoryItem({super.key, required this.date, required this.address, required this.price});

  final String date;
  final String address;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: AppColor.lightBlue),
      child: Row(
        children: [
          Image.asset(AppImages.key, width: 42, height: 42),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: context.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600, fontSize: 15)),
                SizedBox(height: 4),
                Text(
                  address,
                  style: context.textTheme.bodyMedium!.copyWith(fontSize: 11, fontWeight: FontWeight.w400),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 40),
          Text('\$$price', style: context.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w400, fontSize: 13)),
        ],
      ),
    );
  }
}

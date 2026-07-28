import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';

class InfoItem extends StatelessWidget {
  const InfoItem({super.key, required this.title, required this.info});

  final String title;
  final String info;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.textTheme.bodySmall!.copyWith(
            fontSize: 11,
            color: AppColor.grey2,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 4),
        Text(info, style: context.textTheme.bodySmall!.copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

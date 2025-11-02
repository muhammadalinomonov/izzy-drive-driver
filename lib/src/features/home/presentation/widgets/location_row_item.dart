import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';

class LocationRowItem extends StatelessWidget {
  const LocationRowItem({super.key, required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            height: 18,
            width: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColor.lightBlue),
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColor.blueMain),
              width: 12,
              height: 12,
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: context.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w400, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

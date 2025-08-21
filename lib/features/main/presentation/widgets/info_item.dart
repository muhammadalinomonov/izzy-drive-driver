import 'package:flutter/material.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/core/utils/context_extensions.dart';

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
            fontSize: 12,
            color: gray4,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 4),
        Text(
          info,
          style: context.textTheme.bodySmall!.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

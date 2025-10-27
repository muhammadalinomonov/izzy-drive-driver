import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';

class OutputItem extends StatelessWidget {
  const OutputItem({super.key, required this.title, required this.date, required this.price});

  final String title;
  final String date;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          margin: EdgeInsets.only(right: 12),
          padding: EdgeInsets.all(9),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: AppColor.lightBlue),
          child: SvgPicture.asset(AppIcons.key),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.textTheme.headlineLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w400)),
              SizedBox(height: 2),
              Text(
                date,
                style: context.textTheme.headlineLarge!.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColor.grey,
                ),
              ),
            ],
          ),
        ),
        Text(price, style: context.textTheme.headlineLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w400)),
      ],
    );
  }
}

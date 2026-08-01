import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';

class OrderStatusRowItem extends StatelessWidget {
  const OrderStatusRowItem({super.key, required this.isActive, required this.icon, required this.isDone});

  final bool isActive;
  final String icon;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      width: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone
            ? Color(0xffE0F0FF)
            : isActive
            ? AppColor.blueMain
            : AppColor.lightBlue,
      ),
      child: SvgPicture.asset(
        icon,
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(
          isDone
              ? AppColor.blueMain
              : isActive
              ? AppColor.white
              : AppColor.black,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

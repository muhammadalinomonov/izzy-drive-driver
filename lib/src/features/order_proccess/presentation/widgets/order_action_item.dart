import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';

class OrderActionItem extends StatelessWidget {
  const OrderActionItem({super.key, required this.icon, required this.text, required this.onTap});

  final String icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColor.lightBlue),
            alignment: Alignment.center,
            child: Center(child: SvgPicture.asset(icon, width: 20, height: 20)),
          ),
        ),
        SizedBox(height: 8),
        Text(text, style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w500, fontSize: 12)),
      ],
    );
  }
}

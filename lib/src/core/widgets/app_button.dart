import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    this.backGroundColor,
    this.textColor,
    super.key,
    required this.title,
    required this.onTap,
  });

  final String title;
  final Color? backGroundColor;
  final Color? textColor;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            backGroundColor ?? AppColor.kPrimaryColor, // Or use AppColor.primary if defined
        minimumSize: Size(double.infinity, 48), // Full width, height 64
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50), // Fully rounded
        ),
        elevation: 0, // Flat look, remove if you want shadow
      ),
      child: Text(
        title,
        style: context.textS.titleMedium!.copyWith(
          color: textColor ??  AppColor.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

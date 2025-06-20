import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';

class AppButton extends StatelessWidget {
  const AppButton({super.key, required this.title, required this.onTap});

  final String title;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            AppColor.kPrimaryColor, // Or use AppColor.primary if defined
        minimumSize: Size(double.infinity, 48), // Full width, height 64
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50), // Fully rounded
        ),
        elevation: 0, // Flat look, remove if you want shadow
      ),
      child: Text(
        title,
        style: context.textS.titleMedium!.copyWith(
          color: AppColor.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

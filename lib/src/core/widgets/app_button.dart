import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    this.backGroundColor,
    this.textColor,
    this.isLoading = false,
    super.key,
    required this.title,
    required this.onTap,
    this.size,
    this.padding,
  });

  final String title;
  final Color? backGroundColor;
  final Color? textColor;
  final bool isLoading;
  final Size? size;
  final EdgeInsets? padding;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? (){} : onTap,
      style: ElevatedButton.styleFrom(
        padding: padding,
        fixedSize: size,
        backgroundColor:
            backGroundColor ??
            AppColor.kPrimaryColor, // Or use AppColor.primary if defined
        minimumSize: Size(double.infinity, 48), // Full width, height 64
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50), // Fully rounded
        ),
        elevation: 0, // Flat look, remove if you want shadow
      ),
      child: isLoading
          // SizedBox kerak - aks holda Center cheksiz joyni egallab, tugmani
          // butun bo'sh joyga kengaytirib yuboradi (ayniqsa FAB slotida).
          ? SizedBox(
              width: 20,
              height: 20,
              child: CupertinoActivityIndicator(color: AppColor.white),
            )
          : Text(
              title,
              style: context.textS.titleMedium!.copyWith(
                color: textColor ?? AppColor.white,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

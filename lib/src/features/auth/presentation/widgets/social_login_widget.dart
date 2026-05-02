import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';

class SocialLoginWidget extends StatelessWidget {
  const SocialLoginWidget({
    this.size,
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
    this.isLoading = false,
  });

  final String title;
  final String icon;
  final Size? size;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        fixedSize: size,
        backgroundColor: AppColor.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: AppColor.grey.withAlpha(10), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CupertinoActivityIndicator(),
            )
          else
            SvgPicture.asset(icon),
          const SizedBox(width: 12),
          Text(title, style: context.textS.titleMedium),
        ],
      ),
    );
  }
}

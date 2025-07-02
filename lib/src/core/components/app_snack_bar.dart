import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';

class AppSnackBar {
  static void showSuccess(BuildContext context, String message) {
    _showCustomSnackBar(
      context,
      message,
      icon: Icons.check_circle_rounded,
      backgroundColor: AppColor.lightGreen,
      iconColor: Colors.green.shade700,
      textColor: AppColor.black,
    );
  }

  static void showError(BuildContext context, String message) {
    _showCustomSnackBar(
      context,
      message,
      icon: Icons.error_rounded,
      backgroundColor: AppColor.red,
      iconColor: AppColor.white,
      textColor: AppColor.white,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showCustomSnackBar(
      context,
      message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: Colors.amber.shade100,
      iconColor: Colors.amber.shade800,
      textColor: Colors.amber.shade900,
    );
  }

  static void _showCustomSnackBar(
    BuildContext context,
    String message, {
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required Color textColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: backgroundColor,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  message,
                  style: context.textS.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

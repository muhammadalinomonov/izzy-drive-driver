import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_button.dart';

class CommonBottomSheet extends StatelessWidget {
  const CommonBottomSheet({
    super.key,
    required this.children,
    required this.onSave,
    this.buttonText,
    required this.title,
    this.isLoading = false,
  });

  final List<Widget> children;
  final VoidCallback onSave;
  final String? buttonText;
  final String title;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        color: AppColor.lightBlue,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.only(left: 14, top: 12, bottom: 18, right: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24), bottom: Radius.circular(12)),
              color: AppColor.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(color: AppColor.grey2, borderRadius: BorderRadius.circular(2)),
                  margin: EdgeInsets.only(bottom: 25),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: context.textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.w600, fontSize: 20),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              color: AppColor.white,
            ),
            padding: EdgeInsets.only(left: 12, top: 2, bottom: 8 + context.padding.bottom, right: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
          CommonButton(
            isLoading: isLoading,
            onTap: () {
              onSave();
              Navigator.of(context).pop();
            },
            text: buttonText ?? 'Saqlash',
            margin: EdgeInsets.only(
              top: 24,
              left: 12,
              right: 12,
              bottom: context.padding.bottom + MediaQuery.viewInsetsOf(context).bottom,
            ),
          ),
        ],
      ),
    );
  }
}

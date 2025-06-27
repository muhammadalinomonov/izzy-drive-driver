import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';

class AuthInputWidget extends StatelessWidget {
  const AuthInputWidget({super.key, required this.hint, required this.label});

  final String hint, label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textS.titleSmall!.copyWith(
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 10),
        TextFormField(
          obscureText: true,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: context.textS.titleMedium!.copyWith(
              color: AppColor.lightGreyBlue,
              fontWeight: FontWeight.w400,
            ),
            fillColor: AppColor.lightBlue,
            filled: true,
            labelStyle: TextStyle(color: AppColor.grey),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColor.kPrimaryColor),
            ),
          ),
        ),
      ],
    );
  }
}

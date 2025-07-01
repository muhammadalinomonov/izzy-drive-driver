import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';

class AuthInputWidget extends StatelessWidget {
  const AuthInputWidget({
    super.key,
    required this.hint,
    required this.label,
    this.controller,
    this.validator,
    this.obscureText = false,
  });

  final String hint, label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;

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
          controller: controller,
          validator: validator,
          obscureText: obscureText,
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';

/// Digits-only price input with "UZS" suffix.
/// Sanitization (strip non-digits) happens in the BLoC; this widget just
/// rejects non-digit keystrokes for nicer UX.
class PriceInput extends StatelessWidget {
  const PriceInput({super.key, required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        hintText: '0',
        suffixText: '\$',
        suffixStyle: TextStyle(color: AppColor.grey, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: AppColor.lightBlue,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColor.kPrimaryColor),
        ),
      ),
    );
  }
}

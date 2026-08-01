import 'package:flutter/material.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/core/extensions/text_style_extension.dart';

class AuthInputWidget extends StatefulWidget {
  const AuthInputWidget({
    super.key,
    required this.hint,
    required this.label,
    this.controller,
    this.validator,
    this.textInputAction,
    this.textInputType,
    this.obscureText = false,
    this.isPassword = false,
    this.readOnly,
    this.onFieldSubmitted,
  });

  final String hint, label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final bool isPassword;
  final TextInputAction? textInputAction;
  final TextInputType? textInputType;
  final bool? readOnly;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<AuthInputWidget> createState() => _AuthInputWidgetState();
}

class _AuthInputWidgetState extends State<AuthInputWidget> with SingleTickerProviderStateMixin {
  late bool _obscureText;
  late AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _iconController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200), upperBound: 0.5);
    if (!_obscureText) {
      _iconController.value = 0.5;
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  void _toggleObscure() {
    setState(() {
      _obscureText = !_obscureText;
      if (_obscureText) {
        _iconController.reverse();
      } else {
        _iconController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: context.textS.titleSmall!.copyWith(fontWeight: FontWeight.w400)),
        const SizedBox(height: 6),
        TextFormField(
          canRequestFocus: !(widget.readOnly ?? false),
          readOnly: widget.readOnly ?? false,
          controller: widget.controller,
          validator: widget.validator,
          obscureText: widget.isPassword ? _obscureText : widget.obscureText,
          keyboardType: widget.textInputType,
          textInputAction: widget.textInputAction ?? TextInputAction.next,
          onFieldSubmitted: widget.onFieldSubmitted,
          obscuringCharacter: '*',
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            hintText: widget.hint,
            hintStyle: context.textS.titleMedium!.copyWith(color: AppColor.lightGreyBlue, fontWeight: FontWeight.w400),
            fillColor: AppColor.lightBlue,
            filled: true,

            labelStyle: TextStyle(color: AppColor.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColor.red),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColor.kPrimaryColor),
            ),
            suffixIcon: widget.isPassword
                ? GestureDetector(
                    onTap: _toggleObscure,
                    child: AnimatedBuilder(
                      animation: _iconController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _iconController.value * 3.1416 * 2,
                          child: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: AppColor.grey),
                        );
                      },
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';

class SearchInputWidget extends StatefulWidget {
  const SearchInputWidget({
    super.key,
    required this.hint,
    this.controller,
    this.validator,
    this.textInputAction,
    this.textInputType,
    this.obscureText = false,
    this.isPassword = false,
  });

  final String hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final bool isPassword;
  final TextInputAction? textInputAction;
  final TextInputType? textInputType;

  @override
  State<SearchInputWidget> createState() => _SearchInputWidgetState();
}

class _SearchInputWidgetState extends State<SearchInputWidget>
    with SingleTickerProviderStateMixin {
  late bool _obscureText;
  late AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      upperBound: 0.5,
    );
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
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      obscureText: widget.isPassword ? _obscureText : widget.obscureText,
      keyboardType: widget.textInputType,
      textInputAction: widget.textInputAction ?? TextInputAction.next,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 10),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SvgPicture.asset(AppIcons.search),
        ),
        hintText: widget.hint,
        hintStyle: context.textS.titleMedium!.copyWith(
          color: AppColor.lightGreyBlue,
          fontWeight: FontWeight.w400,
        ),
        fillColor: AppColor.lightBlue,
        filled: true,
        labelStyle: TextStyle(color: AppColor.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColor.red),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
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
                      child: Icon(
                        _obscureText
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColor.grey,
                      ),
                    );
                  },
                ),
              )
            : null,
      ),
    );
  }
}

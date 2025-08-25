import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/icons.dart';
import 'package:mechanic/core/utils/context_extensions.dart';

class CommonTextField extends StatefulWidget {
  const CommonTextField({
    super.key,
    this.controller,
    this.title,
    this.hint,
    this.onChanged,
    this.isPassword = false,
    this.suffixIcon,
    this.hasError = false,
  });

  final TextEditingController? controller;
  final String? title;
  final String? hint;
  final Function(String)? onChanged;
  final bool isPassword;
  final Widget? suffixIcon;
  final bool hasError;

  @override
  State<CommonTextField> createState() => _CommonTextFieldState();
}

class _CommonTextFieldState extends State<CommonTextField> {
  final FocusNode _focusNode = FocusNode();
  late bool isPasswordVisible;

  @override
  void initState() {
    super.initState();

    isPasswordVisible = widget.isPassword;
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant CommonTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError != oldWidget.hasError) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null && widget.title!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              widget.title!,
              style: context.textTheme.titleSmall,
            ),
          ),
        Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.hasError
                  ? red
                  : _focusNode.hasFocus
                      ? white
                      : solitude,
            ),
          ),
          child: TextField(
            obscureText: isPasswordVisible,
            obscuringCharacter: '*',
            focusNode: _focusNode,
            cursorColor: mainColor,
            controller: widget.controller,
            onChanged: widget.onChanged,
            style: context.textTheme.displaySmall,
            decoration: InputDecoration(
              suffixIconConstraints: BoxConstraints(
                maxHeight: 24,
                minHeight: 24,
                maxWidth: 32,
                minWidth: 32,
              ),
              suffixIcon: widget.suffixIcon ??
                  (widget.isPassword
                      ? GestureDetector(
                          onTap: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                          child: Container(
                              height: 24,
                              width: 24,
                              margin: EdgeInsets.only(right: 8),
                              child: SvgPicture.asset(
                                isPasswordVisible ? AppIcons.eye : AppIcons.eyeOff,
                                width: 24,
                                height: 24,
                              )),
                        )
                      : null),
              constraints: BoxConstraints(
                maxHeight: 48,
                minHeight: 48,
              ),
              focusColor: white,
              // filled: true,
              fillColor: solitude,
              contentPadding: EdgeInsets.only(top: 4, left: 12),
              hintText: widget.hint,
              hintStyle: context.textTheme.displaySmall!.copyWith(color: gray6),
              border: InputBorder.none,

              // fillColor: solitude,
              //
              // filled: true,
              focusedBorder:widget.hasError?null: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color:  mainColor, width: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

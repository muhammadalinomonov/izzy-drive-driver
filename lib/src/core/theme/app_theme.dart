import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';

class AppTheme {
  static get light => ThemeData(
    colorScheme: ColorScheme.light(
      primary: AppColor.kPrimaryColor,
      brightness: Brightness.light,
    ),
  );
}

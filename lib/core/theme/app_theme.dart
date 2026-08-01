import 'package:flutter/material.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';

class AppTheme {
  static get light => ThemeData(
    fontFamily: 'Inter',
    colorScheme: ColorScheme.light(
      primary: AppColor.kPrimaryColor,
      brightness: Brightness.light,
    ),
    // AppBar uchun yagona "flat" stil. Bu yerda elevation=0 +
    // scrolledUnderElevation=0 + surfaceTintColor=transparent o'rnatish orqali
    // hamma sahifalardagi AppBar scroll qilinganda rangi o'zgarib qolish
    // muammosini bartaraf etamiz. Individual AppBar'larda qaytadan yozish
    // shart emas.
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w400,
        color: AppColor.black,
        letterSpacing: 0,
      ),
      displayMedium: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: AppColor.black,
        letterSpacing: 0,
      ),
      displaySmall: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w400,
        color: AppColor.black,
        letterSpacing: 0,
      ),
      headlineLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w400,
        color: AppColor.black,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w400,
        color: AppColor.black,
        letterSpacing: 0,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: AppColor.black,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColor.black,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColor.black,
        letterSpacing: 0,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColor.black,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColor.black,
        letterSpacing: 0,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColor.black,
        letterSpacing: 0,
      ),
      bodySmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColor.black,
        letterSpacing: 0,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColor.black,
        letterSpacing: 0,
      ),
      labelMedium: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColor.black,
        letterSpacing: 0,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColor.black,
        letterSpacing: 0,
      ),
    ),
  );
}

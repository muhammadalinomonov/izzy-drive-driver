import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mechanic/assets/colors/colors.dart';

class AppTheme {
  static ThemeData themeData = ThemeData(
    scaffoldBackgroundColor: solitude,
    useMaterial3: false,
    dividerTheme: DividerThemeData(
      color: gray2,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
    ),
    primaryColor: white,
    textTheme: const TextTheme(
      bodySmall: bodySmall,
      bodyMedium: bodyMedium,
      bodyLarge: bodyLarge,
      titleSmall: titleSmall,
      titleMedium: titleMedium,
      titleLarge: titleLarge,
      displaySmall: displaySmall,
      displayMedium: displayMedium,
      displayLarge: displayLarge,
    ),
  );

  static const displayLarge =
      TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: black, fontFamily: 'Inter', letterSpacing: .1);

  static const displayMedium =
      TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: black, fontFamily: 'Inter', letterSpacing: .1);

  static const displaySmall =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: black, fontFamily: 'Inter', letterSpacing: .1);

  static const titleLarge =
      TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: black, fontFamily: 'Inter', letterSpacing: .1);

  static const titleMedium =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: black, fontFamily: 'Inter', letterSpacing: .1);

  static const titleSmall =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: black, fontFamily: 'Inter', letterSpacing: .1);

  static const bodyLarge =
      TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: black, fontFamily: 'Inter', letterSpacing: .1);

  static const bodyMedium =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: black, fontFamily: 'Inter', letterSpacing: .1);

  static const bodySmall =
      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: black, fontFamily: 'Inter', letterSpacing: .1);
}

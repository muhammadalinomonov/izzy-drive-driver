import 'package:flutter/material.dart';

extension TextStyleExtension on BuildContext {
  TextTheme get textS => Theme.of(this).textTheme;
}

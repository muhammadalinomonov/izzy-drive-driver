//write extensions for BuildContext class to get screenWidth and screenHeight and padding
import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  Size get sizeOf => MediaQuery.of(this).size;

  EdgeInsets get padding => MediaQuery.of(this).padding;

  TextTheme get textTheme => Theme.of(this).textTheme;

  ThemeData get theme => Theme.of(this);
}

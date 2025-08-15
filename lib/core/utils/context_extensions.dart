import 'package:mechanic/assets/colors/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:vibration/vibration.dart';

enum PopUpStatus { error, warning, success }
extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => theme.textTheme;

  ColorScheme get colorScheme => theme.colorScheme;

  EdgeInsets get padding => MediaQuery.paddingOf(this);

  Size get sizeOf => MediaQuery.sizeOf(this);

  Future<void> showPopUp({
    required PopUpStatus status,
    Widget? child,
    double? height,
    String? message,
    Duration? displayDuration,
    Duration? animationDuration,
    Duration? reverseAnimationDuration,
    DismissType? dismissType,
    TextStyle? messageStyle,
  }) async {
    if (status == PopUpStatus.error) {
      await Vibration.vibrate(duration: 400);
    } else if (status == PopUpStatus.warning) {
      await Vibration.vibrate(duration: 200);
    }
    AnimationController? localAnimationController;
    showTopSnackBar(
      Overlay.of(this),
      Material(
        color: Colors.transparent,
        child: child ??
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4).copyWith(right: 0),
              height: height ?? 52,
              decoration: BoxDecoration(
                color: white,
                border: Border.all(color: status == PopUpStatus.error ? red : status == PopUpStatus.warning ? Colors.yellow : green, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(statusIcon(status), width: 32,height: 32, color: status == PopUpStatus.error ? red : status == PopUpStatus.warning ? red : Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: messageStyle ?? const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
      ),
      displayDuration: displayDuration ?? const Duration(seconds: 3),
      animationDuration: animationDuration ?? const Duration(milliseconds: 250),
      reverseAnimationDuration: reverseAnimationDuration ?? const Duration(milliseconds: 250),
      dismissType: dismissType ?? DismissType.onSwipe
      // onDismissed: (status) {
      //   localAnimationController?.dispose();
      // },
    );
  }
}

String statusIcon(PopUpStatus status) {
  switch (status) {
    case PopUpStatus.error:
      return 'assets/icons/x.svg';
    case PopUpStatus.warning:
      return 'assets/icons/warning.svg';
    case PopUpStatus.success:
      return 'assets/icons/success.svg';
  }
}
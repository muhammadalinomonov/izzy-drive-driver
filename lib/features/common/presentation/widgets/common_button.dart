import 'package:flutter/cupertino.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/common/presentation/widgets/common_scalel_animation.dart';

class CommonButton extends StatelessWidget {
  const CommonButton({
    super.key,
    this.text,
    required this.onTap,
    this.isLoading = false,
    this.isDisabled = false,
    this.height = 48,
    this.child,
    this.color,
    this.borderRadius = 50,
  });

  final String? text;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isDisabled;
  final double? height;
  final Widget? child;
  final Color? color;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return CommonScaleAnimation(
      onTap: isDisabled || isLoading ? null : onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDisabled ? (color ?? mainColor).withValues(alpha: 0.5) : color ?? mainColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: CupertinoButton(
          onPressed: isDisabled ? null : onTap,
          padding: EdgeInsets.zero,
          child: isLoading
              ? CupertinoActivityIndicator(color: white)
              : child ??
                  Text(
                    text ?? '',
                    style: context.textTheme.titleMedium!.copyWith(color: white),
                  ),
        ),
      ),
    );
  }
}

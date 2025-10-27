import 'package:flutter/cupertino.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_scalel_animation.dart';

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
    this.border,
    this.margin,
    this.textColor,
  });

  final String? text;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isDisabled;
  final double? height;
  final Widget? child;
  final Color? color;
  final Color? textColor;
  final double borderRadius;
  final BoxBorder? border;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: CommonScaleAnimation(
        onTap: isDisabled || isLoading ? null : onTap,
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDisabled ? (color ?? AppColor.blueMain).withValues(alpha: 0.5) : color ?? AppColor.blueMain,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border,
          ),
          child: CupertinoButton(
            onPressed: isDisabled ? null : onTap,
            padding: EdgeInsets.zero,
            child: isLoading
                ? CupertinoActivityIndicator(color: AppColor.white)
                : child ??
                      Text(
                        text ?? '',
                        style: context.textTheme.titleMedium!.copyWith(color: textColor ?? AppColor.white),
                      ),
          ),
        ),
      ),
    );
  }
}

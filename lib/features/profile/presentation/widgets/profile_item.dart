import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/icons.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/common/presentation/widgets/common_scalel_animation.dart';

class ProfileItem extends StatelessWidget {
  const ProfileItem({
    super.key,
    required this.icon,
    required this.title,
    this.data = '',
    this.onTap,
  });

  final String icon;
  final String title;
  final String data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CommonScaleAnimation(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            SvgPicture.asset(icon),
            SizedBox(width: 18),
            Expanded(
              child: Text(
                title,
                style: context.textTheme.bodyMedium!.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              data,
              style: context.textTheme.bodyMedium!.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: gray4,
              ),
            ),
            SizedBox(width: 8),
            SvgPicture.asset(AppIcons.chevronRight)
          ],
        ),
      ),
    );
  }
}

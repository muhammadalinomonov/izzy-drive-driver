import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';
import 'package:taxi_app/src/core/localization/locale_keys.g.dart';
import 'package:taxi_app/src/core/widgets/app_button.dart';

class EmailConfirmationWidget extends StatelessWidget {
  const EmailConfirmationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColor.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(AppIcons.gmail),
          SizedBox(height: 30),
          Text(
            LocaleKeys.auth_emailConfirmation_title.tr(),
            style: context.textS.titleLarge!.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          Text(
            LocaleKeys.auth_emailConfirmation_body.tr(
              namedArgs: {'email': 'Faksa.the@gmail.com'},
            ),
            style: context.textS.titleMedium!.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 30),
          AppButton(
            title: LocaleKeys.auth_emailConfirmation_understood.tr(),
            onTap: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

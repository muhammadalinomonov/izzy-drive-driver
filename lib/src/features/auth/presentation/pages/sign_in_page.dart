import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/constants/color/app_images.dart';
import 'package:taxi_app/src/core/extensions/size_extension.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';
import 'package:taxi_app/src/core/widgets/app_button.dart';
import 'package:taxi_app/src/features/auth/presentation/widgets/auth_input_widget.dart';
import 'package:taxi_app/src/features/auth/presentation/widgets/social_login_widget.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(children: [Image.asset(AppImages.loginbg)]),
          Positioned(
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: context.h * 0.35),
              height: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 24),
              decoration: BoxDecoration(
                color: AppColor.white,
                boxShadow: [
                  BoxShadow(
                    offset: Offset(0, -8),
                    blurRadius: 40,
                    spreadRadius: 2,
                    color: AppColor.black.withAlpha(100),
                  ),
                ],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tizimga kirish',
                      style: context.textS.headlineSmall!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 24),
                    SocialLoginWidget(
                      title: 'Google orqali davom ettirish',
                      icon: AppIcons.google,
                    ),
                    SizedBox(height: 18),
                    SocialLoginWidget(
                      title: 'Sign up with Apple',
                      icon: AppIcons.apple,
                    ),
                    SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColor.lightGrey)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Yoki e-mail va parolni kiriting',
                            style: context.textS.titleSmall!.copyWith(
                              color: AppColor.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColor.lightGrey)),
                      ],
                    ),
                    SizedBox(height: 18),
                    AuthInputWidget(hint: 'Mailni kiriting', label: 'E-mail'),
                    SizedBox(height: 18),
                    AuthInputWidget(hint: 'Parol kiriting', label: 'Parol'),
                    SizedBox(height: 18),
                    AppButton(title: 'Tizimga kirish', onTap: () {}),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

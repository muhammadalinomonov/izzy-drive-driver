import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/extensions/size_extension.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';
import 'package:taxi_app/src/core/widgets/app_button.dart';
import 'package:taxi_app/src/features/auth/presentation/widgets/auth_input_widget.dart';
import 'package:taxi_app/src/features/auth/presentation/widgets/email_confirmation_widget.dart';
import 'package:taxi_app/src/features/auth/presentation/widgets/social_login_widget.dart';
import 'package:taxi_app/src/routes/pages.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Image.asset(
                    'assets/images/gradient2.png',
                    fit: BoxFit.fill,
                    height: 600,
                  ),
                ),
                Expanded(
                  child: Image.asset(
                    'assets/images/gradient1.png',
                    fit: BoxFit.fill,
                    height: 600,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: kToolbarHeight,
            child: IconButton(
              onPressed: () => context.pop(),
              icon: SvgPicture.asset(AppIcons.back),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 70,
            child: Padding(
              padding: const EdgeInsets.only(right: 14, left: 14, top: 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SocialLoginWidget(
                    title: 'Google orqali davom ettirish',
                    icon: AppIcons.google,
                  ),
                  SizedBox(height: 18),
                  SocialLoginWidget(
                    title: 'Apple orqali davom ettirish',
                    icon: AppIcons.apple,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: MediaQuery.of(context).viewInsets.bottom == 0
                ? context.h * 0.3
                : context.h * 0.2,
            child: AnimatedContainer(
              height: double.infinity,
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: EdgeInsets.only(left: 12, right: 12, top: 24),
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ro’yxatdan o’tish uchun ma’lumotlarni kiriting!',
                      style: context.textS.headlineSmall!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 26),
                    AuthInputWidget(hint: 'Emailni kiriting', label: 'E-mail'),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: AuthInputWidget(
                        hint: 'Ismini kiriting',
                        label: 'Ism',
                      ),
                    ),
                    AuthInputWidget(hint: '*********', label: 'Password'),
                    SizedBox(height: 24),
                    AppButton(
                      title: "Ro'yxatdan o'tish",
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor: Colors.transparent,
                              content: EmailConfirmationWidget(),
                            );
                          },
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Ro’yxatdan o'tib bo'lganmisiz?",
                            style: context.textS.titleSmall!.copyWith(
                              fontWeight: FontWeight.w400,
                              color: AppColor.grey,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go(Pages.signIn),
                            child: Text(
                              'Tizimga kirish',
                              style: context.textS.titleSmall!.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/icons.dart';
import 'package:mechanic/assets/constants/images.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/core/utils/notifications.dart';
import 'package:mechanic/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:mechanic/features/auth/presentation/screens/register_screen.dart';
import 'package:mechanic/features/auth/presentation/widgets/social_auth_item.dart';
import 'package:mechanic/features/common/presentation/widgets/common_button.dart';
import 'package:mechanic/features/common/presentation/widgets/common_text_field.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  bool hasError = false;

  @override
  void initState() {
    super.initState();

    emailController = TextEditingController();
    passwordController = TextEditingController();

    PushNotifications.initFCM();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mainColor,
      body: KeyboardDismisser(
        child: BlocConsumer<AuthBloc, AuthState>(
          listenWhen: (previous, current) => previous.loginStatus != current.loginStatus,
          listener: (context, state) {
            if (state.loginStatus.isSuccess) {
              Navigator.of(context).pop(true);
            } else if (state.loginStatus.isFailure) {
              context.showPopUp(status: PopUpStatus.error, message: 'Login yoki parolda xatolik bor');
              setState(() {
                hasError = true;
              });
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: MediaQuery.paddingOf(context).top + 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Image.asset(AppImages.handHolding),
                  ),
                  Container(
                    height: context.sizeOf.height - 145 - context.padding.top,
                    padding: EdgeInsets.only(
                      top: 24,
                      left: 12,
                      right: 12,
                      bottom: MediaQuery.paddingOf(context).bottom,
                    ),
                    width: MediaQuery.sizeOf(context).width,
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tizimga kirish',
                          style: context.textTheme.displayLarge,
                        ),
                        SizedBox(height: 24),
                        SocialAuthItem(icon: AppIcons.google, title: 'Google orqali davom ettirish'),
                        SizedBox(height: 18),
                        SocialAuthItem(icon: AppIcons.apple, title: 'Apple orqali davom ettirish'),
                        SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(child: Divider(endIndent: 12)),
                            Text(
                              'Yoki e-mail va parolni kiriting',
                              style: context.textTheme.bodySmall!.copyWith(
                                fontSize: 14,
                                color: gray4,
                              ),
                            ),
                            Expanded(child: Divider(indent: 12)),
                          ],
                        ),
                        SizedBox(height: 18),
                        CommonTextField(
                          controller: emailController,
                          title: 'E-mail',
                          hasError: hasError,
                          hint: 'E-mail manzilingizni kiriting',
                          onChanged: (value) {
                            setState(() {
                              hasError = false;
                            });
                          },
                        ),
                        SizedBox(height: 24),
                        CommonTextField(
                          controller: passwordController,
                          title: 'Password',
                          hasError: hasError,
                          hint: 'Passwordingizni kiriting',
                          isPassword: true,
                          onChanged: (value) {
                            setState(() {
                              hasError = false;
                            });
                          },
                        ),
                        SizedBox(height: 24),
                        CommonButton(
                          margin: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
                          text: 'Tizimga kirish',
                          onTap: () {
                            context.read<AuthBloc>().add(LoginUser(
                                  password: passwordController.text.trim(),
                                  username: emailController.text,
                                ));
                          },
                          isLoading: state.loginStatus.isInProgress,
                        ),
                        SizedBox(height: 24),
                        Align(
                          alignment: Alignment.center,
                          child: Text.rich(
                            TextSpan(
                              text: ' Ro’yxatdan o’tmaganmisiz? ',
                              style: context.textTheme.bodySmall!.copyWith(
                                color: gray4,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Ro\'yxatdan o\'tish',
                                  style: context.textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w600),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.of(context).push(
                                        CupertinoPageRoute(
                                          builder: (context) => const RegisterScreen(),
                                        ),
                                      );
                                    },
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

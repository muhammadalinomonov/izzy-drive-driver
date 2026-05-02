import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/components/app_snack_bar.dart';
import 'package:taxi_app/src/core/components/app_validators.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/extensions/size_extension.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';
import 'package:taxi_app/src/core/widgets/app_button.dart';
import 'package:taxi_app/src/features/auth/presentation/bloc/bloc/auth_bloc.dart';
import 'package:taxi_app/src/features/auth/presentation/widgets/auth_input_widget.dart';
import 'package:taxi_app/src/features/auth/presentation/widgets/otp_verification_sheet.dart';
import 'package:taxi_app/src/features/auth/presentation/widgets/social_login_widget.dart';
import 'package:taxi_app/src/routes/pages.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _otpSheetOpen = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _openOtpSheet() async {
    if (_otpSheetOpen) return;
    _otpSheetOpen = true;
    final result = await showOtpVerificationSheet(context);
    _otpSheetOpen = false;
    if (!mounted) return;
    if (result == true) {
      context.go(Pages.tackScreen);
    }
  }

  void _onSocialSuccess() {
    if (!mounted) return;
    context.go(Pages.tackScreen);
  }

  void _onSocialError(String fallback) {
    if (!mounted) return;
    final state = context.read<AuthBloc>().state;
    AppSnackBar.showError(
      context,
      (state.errorMessage?.isNotEmpty ?? false) ? state.errorMessage! : fallback,
    );
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(
          RequestOtpEvent(
            email: _emailController.text.trim(),
            fullName: _nameController.text.trim(),
            password: _passwordController.text.trim(),
            onSuccess: _openOtpSheet,
            onError: () {},
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (p, c) => p.requestOtpStatus != c.requestOtpStatus,
        listener: (context, state) {
          if (state.requestOtpStatus == AuthStatus.failure && !_otpSheetOpen) {
            AppSnackBar.showError(
              context,
              state.errorMessage ?? 'Kod yuborib bo\'lmadi',
            );
          }
        },
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Stack(
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
                      BlocBuilder<AuthBloc, AuthState>(
                        buildWhen: (p, c) => p.googleStatus != c.googleStatus,
                        builder: (context, state) {
                          return SocialLoginWidget(
                            title: 'Google orqali davom ettirish',
                            icon: AppIcons.google,
                            isLoading: state.googleStatus == AuthStatus.loading,
                            onTap: () => context.read<AuthBloc>().add(
                                  GoogleSignInEvent(
                                    onSuccess: _onSocialSuccess,
                                    onError: () => _onSocialError(
                                      'Google orqali kirib bo\'lmadi',
                                    ),
                                  ),
                                ),
                          );
                        },
                      ),
                      if (Platform.isIOS) ...[
                        const SizedBox(height: 18),
                        BlocBuilder<AuthBloc, AuthState>(
                          buildWhen: (p, c) => p.appleStatus != c.appleStatus,
                          builder: (context, state) {
                            return SocialLoginWidget(
                              title: 'Apple orqali davom ettirish',
                              icon: AppIcons.apple,
                              isLoading:
                                  state.appleStatus == AuthStatus.loading,
                              onTap: () => context.read<AuthBloc>().add(
                                    AppleSignInEvent(
                                      onSuccess: _onSocialSuccess,
                                      onError: () => _onSocialError(
                                        'Apple orqali kirib bo\'lmadi',
                                      ),
                                    ),
                                  ),
                            );
                          },
                        ),
                      ],
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
                  padding: const EdgeInsets.only(left: 12, right: 12, top: 24),
                  decoration: BoxDecoration(
                    color: AppColor.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
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
                          const SizedBox(height: 26),
                          AuthInputWidget(
                            textInputType: TextInputType.emailAddress,
                            hint: 'Emailni kiriting',
                            label: 'E-mail',
                            controller: _emailController,
                            validator: AppValidators.email,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: AuthInputWidget(
                              textInputType: TextInputType.text,
                              hint: 'Ismini kiriting',
                              label: 'Ism',
                              controller: _nameController,
                              validator: AppValidators.name,
                            ),
                          ),
                          AuthInputWidget(
                            hint: '*********',
                            label: 'Password',
                            isPassword: true,
                            controller: _passwordController,
                            validator: AppValidators.password,
                            obscureText: true,
                          ),
                          const SizedBox(height: 24),
                          BlocBuilder<AuthBloc, AuthState>(
                            buildWhen: (p, c) =>
                                p.requestOtpStatus != c.requestOtpStatus,
                            builder: (context, state) {
                              return AppButton(
                                isLoading: state.requestOtpStatus ==
                                    AuthStatus.loading,
                                title: "Ro'yxatdan o'tish",
                                onTap: _onSubmit,
                              );
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Ro'yxatdan o'tib bo'lganmisiz?",
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

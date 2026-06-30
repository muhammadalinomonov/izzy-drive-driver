import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/components/app_snack_bar.dart';
import 'package:taxi_app/src/core/components/app_validators.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';
import 'package:taxi_app/src/core/localization/locale_keys.g.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';
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
      (state.errorMessage?.isNotEmpty ?? false)
          ? state.errorMessage!
          : fallback,
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
      backgroundColor: AppColor.white,
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (p, c) => p.requestOtpStatus != c.requestOtpStatus,
        listener: (context, state) {
          if (state.requestOtpStatus == AuthStatus.failure && !_otpSheetOpen) {
            AppSnackBar.showError(
              context,
              state.errorMessage ??
                  LocaleKeys.auth_signUp_otpRequestFailed.tr(),
            );
          }
        },
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsetsGeometry.only(bottom: context.padding.bottom),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Header(
                              onBack: () => context.pop(),
                              googleButton: BlocBuilder<AuthBloc, AuthState>(
                                buildWhen: (p, c) =>
                                    p.googleStatus != c.googleStatus,
                                builder: (context, state) {
                                  return SocialLoginWidget(
                                    title: LocaleKeys.auth_signIn_googleContinue
                                        .tr(),
                                    icon: AppIcons.google,
                                    isLoading:
                                        state.googleStatus ==
                                        AuthStatus.loading,
                                    onTap: () => context.read<AuthBloc>().add(
                                      GoogleSignInEvent(
                                        onSuccess: _onSocialSuccess,
                                        onError: () => _onSocialError(
                                          LocaleKeys.auth_signIn_googleFailed
                                              .tr(),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              appleButton: Platform.isIOS
                                  ? BlocBuilder<AuthBloc, AuthState>(
                                      buildWhen: (p, c) =>
                                          p.appleStatus != c.appleStatus,
                                      builder: (context, state) {
                                        return SocialLoginWidget(
                                          title: LocaleKeys
                                              .auth_signIn_appleContinue
                                              .tr(),
                                          icon: AppIcons.apple,
                                          isLoading:
                                              state.appleStatus ==
                                              AuthStatus.loading,
                                          onTap: () =>
                                              context.read<AuthBloc>().add(
                                                AppleSignInEvent(
                                                  onSuccess: _onSocialSuccess,
                                                  onError: () => _onSocialError(
                                                    LocaleKeys
                                                        .auth_signIn_appleFailed
                                                        .tr(),
                                                  ),
                                                ),
                                              ),
                                        );
                                      },
                                    )
                                  : null,
                            ),
                            Transform.translate(
                              offset: const Offset(0, -18),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  24,
                                  16,
                                  24,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColor.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(18),
                                    topRight: Radius.circular(18),
                                  ),
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        LocaleKeys.auth_signUp_title.tr(),
                                        style: context.textS.headlineSmall!
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 12),
                                      AuthInputWidget(
                                        textInputType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        hint: LocaleKeys.auth_signUp_emailHint
                                            .tr(),
                                        label: LocaleKeys.auth_signUp_emailLabel
                                            .tr(),
                                        controller: _emailController,
                                        validator: AppValidators.email,
                                      ),
                                      const SizedBox(height: 8),
                                      AuthInputWidget(
                                        textInputType: TextInputType.text,
                                        textInputAction: TextInputAction.next,
                                        hint: LocaleKeys.auth_signUp_nameHint
                                            .tr(),
                                        label: LocaleKeys.auth_signUp_nameLabel
                                            .tr(),
                                        controller: _nameController,
                                        validator: AppValidators.name,
                                      ),
                                      const SizedBox(height: 8),
                                      AuthInputWidget(
                                        hint: LocaleKeys
                                            .auth_signUp_passwordHint
                                            .tr(),
                                        label: LocaleKeys
                                            .auth_signUp_passwordLabel
                                            .tr(),
                                        isPassword: true,
                                        controller: _passwordController,
                                        validator: AppValidators.password,
                                        obscureText: true,
                                        textInputAction: TextInputAction.done,
                                        onFieldSubmitted: (_) => _onSubmit(),
                                      ),
                                      const SizedBox(height: 8),
                                      BlocBuilder<AuthBloc, AuthState>(
                                        buildWhen: (p, c) =>
                                            p.requestOtpStatus !=
                                            c.requestOtpStatus,
                                        builder: (context, state) {
                                          return AppButton(
                                            isLoading:
                                                state.requestOtpStatus ==
                                                AuthStatus.loading,
                                            title: LocaleKeys.auth_signUp_submit
                                                .tr(),
                                            onTap: _onSubmit,
                                          );
                                        },
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                LocaleKeys
                                                    .auth_signUp_alreadyRegistered
                                                    .tr(),
                                                style: context.textS.titleSmall!
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: AppColor.grey,
                                                    ),
                                              ),
                                            ),
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 4,
                                                    ),
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              onPressed: () =>
                                                  context.go(Pages.signIn),
                                              child: Text(
                                                LocaleKeys.auth_signUp_signInCta
                                                    .tr(),
                                                style: context.textS.titleSmall!
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColor
                                                          .kPrimaryColor,
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
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Top section: gradient backdrop with the back button and social-login
/// buttons painted over it. Sizes itself to its content so it never clips on
/// small/large screens.
class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
    required this.googleButton,
    this.appleButton,
  });

  final VoidCallback onBack;
  final Widget googleButton;
  final Widget? appleButton;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Image.asset(
                  'assets/images/gradient2.png',
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Image.asset(
                  'assets/images/gradient1.png',
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 14, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: onBack,
                    icon: SvgPicture.asset(AppIcons.back),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: googleButton,
                ),
                if (appleButton != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: appleButton!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

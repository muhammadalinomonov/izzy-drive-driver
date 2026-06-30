import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/components/app_snack_bar.dart';
import 'package:taxi_app/src/core/components/app_validators.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/constants/color/app_images.dart';
import 'package:taxi_app/src/core/extensions/size_extension.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';
import 'package:taxi_app/src/core/localization/locale_keys.g.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';
import 'package:taxi_app/src/core/utils/notifications.dart';
import 'package:taxi_app/src/core/widgets/app_button.dart';
import 'package:taxi_app/src/features/auth/data/model/auth_model.dart';
import 'package:taxi_app/src/features/auth/presentation/bloc/bloc/auth_bloc.dart';
import 'package:taxi_app/src/features/auth/presentation/widgets/auth_input_widget.dart';
import 'package:taxi_app/src/features/auth/presentation/widgets/social_login_widget.dart';
import 'package:taxi_app/src/routes/pages.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _printFcmToken();
  }

  Future<void> _printFcmToken() async {
    final token = await PushNotifications.getToken();
    // ignore: avoid_print
    print('==== FCM TOKEN (sign-in page) ====');
    // ignore: avoid_print
    print(token);
    // ignore: avoid_print
    print('==================================');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSocialSuccess() {
    if (!mounted) return;
    context.go(Pages.main);
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

  Future<void> _onLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final fcmToken = await PushNotifications.getToken();
    if (!mounted) return;
    final authModel = AuthModel(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      fullName: '',
      deviceToken: fcmToken,
    );
    context.read<AuthBloc>().add(
      LoginEvent(
        authModel: authModel,
        onSuccess: () {
          if (!mounted) return;
          context.go(Pages.main);
        },
        onError: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hero image scales with screen but is clamped so it never dominates the
    // layout on large screens (e.g. iPad / iPhone app running on iPad).
    final double imageHeight = (context.h * 0.34)
        .clamp(180.0, 300.0)
        .toDouble();

    return Scaffold(
      backgroundColor: AppColor.white,
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (p, c) => p.loginStatus != c.loginStatus,
        listener: (context, state) {
          if (state.loginStatus == AuthStatus.failure) {
            AppSnackBar.showError(
              context,
              state.errorMessage ?? LocaleKeys.auth_signIn_loginFailed.tr(),
            );
          }
        },
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
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
                          SizedBox(
                            height: imageHeight,
                            width: double.infinity,
                            child: Image.asset(
                              AppImages.loginbg,
                              fit: BoxFit.cover,
                              alignment: Alignment.bottomCenter,
                            ),
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
                                      LocaleKeys.auth_signIn_title.tr(),
                                      style: context.textS.headlineSmall!
                                          .copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    BlocBuilder<AuthBloc, AuthState>(
                                      buildWhen: (p, c) =>
                                          p.googleStatus != c.googleStatus,
                                      builder: (context, state) {
                                        return SocialLoginWidget(
                                          title: LocaleKeys
                                              .auth_signIn_googleContinue
                                              .tr(),
                                          icon: AppIcons.google,
                                          isLoading:
                                              state.googleStatus ==
                                              AuthStatus.loading,
                                          onTap: () =>
                                              context.read<AuthBloc>().add(
                                                GoogleSignInEvent(
                                                  onSuccess: _onSocialSuccess,
                                                  onError: () => _onSocialError(
                                                    LocaleKeys
                                                        .auth_signIn_googleFailed
                                                        .tr(),
                                                  ),
                                                ),
                                              ),
                                        );
                                      },
                                    ),
                                    if (Platform.isIOS) ...[
                                      const SizedBox(height: 8),
                                      BlocBuilder<AuthBloc, AuthState>(
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
                                            onTap: () => context.read<AuthBloc>().add(
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
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: AppColor.lightGrey,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            LocaleKeys.auth_signIn_orWithEmail
                                                .tr(),
                                            style: context.textS.titleSmall!
                                                .copyWith(
                                                  color: AppColor.grey,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: AppColor.lightGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    AuthInputWidget(
                                      hint: LocaleKeys.auth_signIn_emailHint
                                          .tr(),
                                      label: LocaleKeys.auth_signIn_emailLabel
                                          .tr(),
                                      controller: _emailController,
                                      validator: AppValidators.email,
                                      textInputType:
                                          TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                    ),
                                    const SizedBox(height: 8),
                                    AuthInputWidget(
                                      hint: LocaleKeys
                                          .auth_signIn_passwordHint
                                          .tr(),
                                      label: LocaleKeys
                                          .auth_signIn_passwordLabel
                                          .tr(),
                                      isPassword: true,
                                      controller: _passwordController,
                                      validator: AppValidators.password,
                                      obscureText: true,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _onLogin(),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 4,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize
                                              .shrinkWrap,
                                        ),
                                        onPressed: () => context.push(
                                          Pages.forgotPasswordEmail,
                                        ),
                                        child: Text(
                                          LocaleKeys
                                              .auth_signIn_forgotPassword
                                              .tr(),
                                          style: context.textS.titleSmall!
                                              .copyWith(
                                                color: AppColor.kPrimaryColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    BlocBuilder<AuthBloc, AuthState>(
                                      buildWhen: (p, c) =>
                                          p.loginStatus != c.loginStatus,
                                      builder: (context, state) {
                                        return AppButton(
                                          title: LocaleKeys.auth_signIn_title
                                              .tr(),
                                          isLoading:
                                              state.loginStatus ==
                                              AuthStatus.loading,
                                          onTap: _onLogin,
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
                                                  .auth_signIn_notRegisteredYet
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
                                                context.push(Pages.signUp),
                                            child: Text(
                                              LocaleKeys
                                                  .auth_signIn_registerCta
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
    );
  }
}

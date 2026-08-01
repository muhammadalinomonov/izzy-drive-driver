import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/core/components/app_snack_bar.dart';
import 'package:taxi_app/core/components/app_validators.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/core/constants/color/app_icons.dart';
import 'package:taxi_app/core/extensions/text_style_extension.dart';
import 'package:taxi_app/core/localization/locale_keys.g.dart';
import 'package:taxi_app/core/widgets/app_button.dart';
import 'package:taxi_app/features/auth/presentation/bloc/bloc/auth_bloc.dart';
import 'package:taxi_app/features/auth/presentation/bloc/forgot_password_bloc/forgot_password_bloc.dart';
import 'package:taxi_app/features/auth/presentation/widgets/auth_input_widget.dart';
import 'package:taxi_app/features/auth/presentation/widgets/forgot_password_otp_sheet.dart';
import 'package:taxi_app/routes/pages.dart';

class ForgotPasswordEmailPage extends StatefulWidget {
  const ForgotPasswordEmailPage({super.key});

  @override
  State<ForgotPasswordEmailPage> createState() =>
      _ForgotPasswordEmailPageState();
}

class _ForgotPasswordEmailPageState extends State<ForgotPasswordEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _otpSheetOpen = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _openOtpSheet() async {
    if (_otpSheetOpen) return;
    _otpSheetOpen = true;
    final resetToken = await showForgotPasswordOtpSheet(context);
    _otpSheetOpen = false;
    if (!mounted) return;
    if (resetToken != null && resetToken.isNotEmpty) {
      context.push(Pages.resetPassword, extra: {'resetToken': resetToken});
    }
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _emailController.text.trim();
    context.read<ForgotPasswordBloc>().add(
          RequestForgotOtpEvent(
            email: email,
            onSuccess: _openOtpSheet,
            onError: () {},
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
        listenWhen: (p, c) => p.requestOtpStatus != c.requestOtpStatus,
        listener: (context, state) {
          if (state.requestOtpStatus == AuthStatus.failure) {
            AppSnackBar.showError(
              context,
              state.errorMessage.isEmpty
                  ? LocaleKeys.auth_forgotPassword_otpRequestFailed.tr()
                  : state.errorMessage,
            );
          }
        },
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => context.pop(),
                      icon: SvgPicture.asset(AppIcons.back),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      LocaleKeys.auth_forgotPassword_title.tr(),
                      style: context.textS.headlineSmall!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      LocaleKeys.auth_forgotPassword_subtitle.tr(),
                      style: context.textS.titleSmall!.copyWith(
                        color: AppColor.grey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AuthInputWidget(
                      hint: LocaleKeys.auth_forgotPassword_emailHint.tr(),
                      label: LocaleKeys.auth_forgotPassword_emailLabel.tr(),
                      controller: _emailController,
                      validator: AppValidators.email,
                      textInputType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
                      buildWhen: (p, c) =>
                          p.requestOtpStatus != c.requestOtpStatus,
                      builder: (context, state) {
                        return AppButton(
                          title: LocaleKeys.auth_forgotPassword_sendCode.tr(),
                          isLoading:
                              state.requestOtpStatus == AuthStatus.loading,
                          onTap: _onSubmit,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

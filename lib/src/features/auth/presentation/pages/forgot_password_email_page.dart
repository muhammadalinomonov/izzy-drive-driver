import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/components/app_snack_bar.dart';
import 'package:taxi_app/src/core/components/app_validators.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';
import 'package:taxi_app/src/core/widgets/app_button.dart';
import 'package:taxi_app/src/features/auth/presentation/bloc/bloc/auth_bloc.dart';
import 'package:taxi_app/src/features/auth/presentation/bloc/forgot_password_bloc/forgot_password_bloc.dart';
import 'package:taxi_app/src/features/auth/presentation/widgets/auth_input_widget.dart';
import 'package:taxi_app/src/features/auth/presentation/widgets/forgot_password_otp_sheet.dart';
import 'package:taxi_app/src/routes/pages.dart';

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
                  ? 'OTP yuborib bo\'lmadi'
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
                      'Parolni tiklash',
                      style: context.textS.headlineSmall!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Email manzilingizga tasdiqlash kodi yuboriladi',
                      style: context.textS.titleSmall!.copyWith(
                        color: AppColor.grey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 32),
                    AuthInputWidget(
                      hint: 'Mailni kiriting',
                      label: 'E-mail',
                      controller: _emailController,
                      validator: AppValidators.email,
                      textInputType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
                      buildWhen: (p, c) =>
                          p.requestOtpStatus != c.requestOtpStatus,
                      builder: (context, state) {
                        return AppButton(
                          title: 'Kod yuborish',
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

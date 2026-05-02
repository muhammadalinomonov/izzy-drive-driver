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
import 'package:taxi_app/src/routes/pages.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final pass = _passwordController.text;
    final confirm = _confirmController.text;
    if (pass != confirm) {
      AppSnackBar.showError(context, 'Parollar mos kelmadi');
      return;
    }
    context.read<ForgotPasswordBloc>().add(
          ResetPasswordEvent(
            newPassword: pass,
            onSuccess: () {
              AppSnackBar.showSuccess(
                context,
                'Parol yangilandi. Yangi parol bilan kiring',
              );
              context.go(Pages.signIn);
            },
            onError: () {},
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
        listenWhen: (p, c) => p.resetStatus != c.resetStatus,
        listener: (context, state) {
          if (state.resetStatus == AuthStatus.failure) {
            AppSnackBar.showError(
              context,
              state.errorMessage.isEmpty
                  ? 'Parolni yangilab bo\'lmadi'
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
                      'Yangi parol',
                      style: context.textS.headlineSmall!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Yangi parolni kiriting va tasdiqlang',
                      style: context.textS.titleSmall!.copyWith(
                        color: AppColor.grey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 32),
                    AuthInputWidget(
                      hint: 'Yangi parolni kiriting',
                      label: 'Yangi parol',
                      isPassword: true,
                      obscureText: true,
                      controller: _passwordController,
                      validator: AppValidators.password,
                    ),
                    const SizedBox(height: 24),
                    AuthInputWidget(
                      hint: 'Parolni qaytadan kiriting',
                      label: 'Parolni takrorlang',
                      isPassword: true,
                      obscureText: true,
                      controller: _confirmController,
                      validator: AppValidators.password,
                    ),
                    const SizedBox(height: 24),
                    BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
                      buildWhen: (p, c) => p.resetStatus != c.resetStatus,
                      builder: (context, state) {
                        return AppButton(
                          title: 'Saqlash',
                          isLoading: state.resetStatus == AuthStatus.loading,
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

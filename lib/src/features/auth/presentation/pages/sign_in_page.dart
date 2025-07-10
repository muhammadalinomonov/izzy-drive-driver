import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/components/app_snack_bar.dart';
import 'package:taxi_app/src/core/components/app_validators.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/constants/color/app_images.dart';
import 'package:taxi_app/src/core/extensions/size_extension.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';
import 'package:taxi_app/src/core/widgets/app_button.dart';
import 'package:taxi_app/src/features/auth/presentation/widgets/auth_input_widget.dart';
import 'package:taxi_app/src/features/auth/presentation/widgets/social_login_widget.dart';
import 'package:taxi_app/src/routes/pages.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/src/features/auth/data/model/auth_model.dart';
import 'package:taxi_app/src/features/auth/presentation/bloc/bloc/auth_bloc.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isButtonOnProgress = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.loading) {
            setState(() {
              isButtonOnProgress = true;
            });
          } else if (state.status == AuthStatus.success) {
            setState(() {
              isButtonOnProgress = false;
            });
            context.go(Pages.tackScreen);
          } else if (state.status == AuthStatus.failure) {
            setState(() {
              isButtonOnProgress = false;
            });
            AppSnackBar.showError(
              context,
              state.errorMessage ?? 'Login failed',
            );
          }
        },
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Stack(
            children: [
              Column(children: [Image.asset(AppImages.loginbg)]),
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
                  padding: EdgeInsets.only(left: 12, right: 23, top: 24),
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                            title: 'Apple orqali davom ettirish',
                            icon: AppIcons.apple,
                          ),
                          SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(color: AppColor.lightGrey),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'Yoki e-mail va parolni kiriting',
                                  style: context.textS.titleSmall!.copyWith(
                                    color: AppColor.grey,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: AppColor.lightGrey),
                              ),
                            ],
                          ),
                          SizedBox(height: 18),
                          AuthInputWidget(
                            hint: 'Mailni kiriting',
                            label: 'E-mail',
                            controller: _emailController,
                            validator: AppValidators.email,
                          ),
                          SizedBox(height: 18),
                          AuthInputWidget(
                            hint: 'Parol kiriting',
                            label: 'Parol',
                            isPassword: true,
                            controller: _passwordController,
                            validator: AppValidators.password,
                            obscureText: true,
                          ),
                          SizedBox(height: 18),
                          AppButton(
                            title: 'Tizimga kirish',
                            isLoading: isButtonOnProgress,
                            onTap: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                final deviceToken = 'qweerefdsfds232423';
                                final authModel = AuthModel(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text.trim(),
                                  fullName: '',
                                  deviceToken: deviceToken,
                                );
                                context.read<AuthBloc>().add(
                                  LoginEvent(
                                    authModel: authModel,
                                    onError: () {
                                      setState(() {
                                        isButtonOnProgress = false;
                                      });
                                    },
                                    onSuccess: () {
                                      setState(() {
                                        isButtonOnProgress = false;
                                      });
                                      context.go(Pages.tackScreen);
                                    },
                                  ),
                                );
                              } else {
                                print('validate error');
                              }
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Ro’yxatdan o’tmaganmisiz?',
                                  style: context.textS.titleSmall!.copyWith(
                                    fontWeight: FontWeight.w400,
                                    color: AppColor.grey,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.push(Pages.signUp),
                                  child: Text(
                                    'Ro’xatdan o’tish',
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

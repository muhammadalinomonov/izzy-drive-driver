import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:formz/formz.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/icons.dart';
import 'package:mechanic/assets/constants/images.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mechanic/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:mechanic/features/auth/presentation/blocs/authentication/authentication_bloc.dart';
import 'package:mechanic/features/auth/presentation/widgets/social_auth_item.dart';
import 'package:mechanic/features/common/presentation/widgets/common_button.dart';
import 'package:mechanic/features/common/presentation/widgets/common_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late TextEditingController emailController;
  late TextEditingController nameController;
  late TextEditingController passwordController;
  bool hasError = false;

  @override
  void initState() {
    super.initState();

    emailController = TextEditingController();
    nameController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) => previous.registerStatus != current.registerStatus,
        listener: (context, state) {
          if (state.registerStatus.isSuccess) {
            context
                .read<AuthenticationBloc>()
                .add(AuthenticationStatusChanged(status: AuthenticationStatus.authenticated));
          } else if (state.registerStatus.isFailure) {
            context.showPopUp(status: PopUpStatus.error, message: state.errorMessage);
            setState(() {
              hasError = true;
            });
          }
        },
        builder: (context, state) {
          return KeyboardDismisser(
            child: Stack(
              children: [
                Image.asset(AppImages.appBarGradient),
                Padding(
                  padding: EdgeInsets.only(
                    left: 10,
                    right: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: MediaQuery.paddingOf(context).top),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: SvgPicture.asset(AppIcons.arrowBack),
                        ),
                      ),
                      SizedBox(height: 16),
                      SocialAuthItem(icon: AppIcons.google, title: 'Google orqali davom ettirish'),
                      SizedBox(height: 18),
                      SocialAuthItem(icon: AppIcons.apple, title: 'Apple orqali davom ettirish'),
                    ],
                  ),
                ),
                Positioned(
                  top: 189 + 44,
                  bottom: 0,
                  child: SingleChildScrollView(
                    child: Container(
                      height: context.sizeOf.height - 189 - context.padding.top,
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
                            'Ro’yxatdan o’tish uchun ma’lumotlarni kiriting!',
                            style: context.textTheme.displayLarge!.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 26),
                          CommonTextField(
                            title: 'E-mail',
                            hint: 'E-mail manzilingizni kiriting',
                            controller: emailController,
                            hasError: hasError,
                            onChanged: (value) {
                              setState(() {
                                hasError = false;
                              });
                            },
                          ),
                          SizedBox(height: 24),
                          CommonTextField(
                            title: 'Ism',
                            hint: 'Ismni kiriting',
                            hasError: hasError,
                            onChanged: (value) {
                              setState(() {
                                hasError = false;
                              });
                            },
                            controller: nameController,
                          ),
                          SizedBox(height: 24),
                          CommonTextField(
                            title: 'Password',
                            hint: 'Passwordingizni kiriting',
                            isPassword: true,
                            hasError: hasError,
                            onChanged: (value) {
                              setState(() {
                                hasError = false;
                              });
                            },
                            controller: passwordController,
                          ),
                          SizedBox(height: 24),
                          CommonButton(
                            margin: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
                            text: 'Ro’yxatdan o’tish',
                            onTap: () {
                              context.read<AuthBloc>().add(
                                RegisterUser(
                                  email: emailController.text,
                                  firstName: nameController.text,
                                  password: passwordController.text,
                                ),
                              );
                              // showDialog(
                              //     context: context,
                              //     builder: (BuildContext context) {
                              //       return Dialog(
                              //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              //         child: Padding(
                              //           padding: const EdgeInsets.all(24.0),
                              //           child: Column(
                              //             mainAxisSize: MainAxisSize.min,
                              //             children: [
                              //               SvgPicture.asset(
                              //                 AppIcons.email, // <-- Make sure you add this image to assets
                              //                 width: 60,
                              //                 height: 60,
                              //               ),
                              //               const SizedBox(height: 20),
                              //               const Text(
                              //                 'Akkauntni tasdiqlang',
                              //                 style: TextStyle(
                              //                   fontSize: 20,
                              //                   fontWeight: FontWeight.bold,
                              //                 ),
                              //               ),
                              //               const SizedBox(height: 12),
                              //               Text(
                              //                 'sdsdfdsf@gmail.com orqali akkauntingizni aktivlashtiring!',
                              //                 textAlign: TextAlign.center,
                              //                 style: const TextStyle(fontSize: 16),
                              //               ),
                              //               const SizedBox(height: 24),
                              //               CommonButton(
                              //                 onTap: () {
                              //                   Navigator.of(context).pop();
                              //                   Navigator.of(context).push(
                              //                       CupertinoPageRoute(builder: (context) => FillUserDataScreen()));
                              //                 },
                              //                 text: 'Tushunarli',
                              //               )
                              //             ],
                              //           ),
                              //         ),
                              //       );
                              //     });
                            },
                            isLoading: state.registerStatus.isInProgress,
                          ),
                          SizedBox(height: 24),
                          Align(
                            alignment: Alignment.center,
                            child: Text.rich(
                              TextSpan(
                                text: ' Ro’yxatdan o’tib bo’lganmisiz? ',
                                style: context.textTheme.bodySmall!.copyWith(
                                  color: gray4,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Tizimga kirish',
                                    style: context.textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w600),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.of(context).pop();
                                      },
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

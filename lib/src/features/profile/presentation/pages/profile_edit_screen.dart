import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/components/app_validators.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';
import 'package:taxi_app/src/features/auth/presentation/widgets/auth_input_widget.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_button.dart';
import 'package:taxi_app/src/features/profile/presentation/bloc/profile_bloc.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _newConfirmPasswordController;
  bool canEditPassword = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileBloc>().state.profile;
    _emailController = TextEditingController(text: profile?.email);
    _passwordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _newConfirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    _newConfirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        backgroundColor: AppColor.white,
        leading: IconButton(onPressed: () => context.pop(), icon: Icon(Icons.arrow_back)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          return CommonButton(
            isLoading: state.updatePasswordStatus.isInProgress,
            text: 'Save',
            onTap: () {
              context.read<ProfileBloc>().add(
                UpdatePasswordEvent(
                  oldPassword: _passwordController.text,
                  newPassword: _newPasswordController.text,
                  onSuccess: () {
                    //show pop up success message
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Password changed successfully')));
                    setState(() {
                      canEditPassword = false;
                    });
                  },
                  onError: (errorMessage) {
                    //show pop up error message
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
                  },
                ),
              );
            },
            margin: EdgeInsets.only(left: 16, right: 16),
            isDisabled: !canEditPassword,
          );
        },
      ),
      body: SingleChildScrollView(
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My information',
                    style: context.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600, fontSize: 20),
                  ),
                  SizedBox(height: 24),
                  AuthInputWidget(
                    hint: '',
                    label: 'E-mail',
                    readOnly: true,
                    controller: _emailController,
                  ),
                  SizedBox(height: 24),
                  AuthInputWidget(
                    hint: '',
                    label: 'Name',
                    readOnly: true,
                    controller: TextEditingController(text: state.profile?.fullName),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Change password',
                        style: context.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w500, fontSize: 16),
                      ),
                      CupertinoSwitch(
                        value: canEditPassword,
                        onChanged: (value) {
                          setState(() {
                            canEditPassword = !canEditPassword;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  Opacity(
                    opacity: canEditPassword ? 1 : .5,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AuthInputWidget(
                          readOnly: !canEditPassword,
                          hint: 'Enter password',
                          label: 'Old password',
                          isPassword: true,
                          controller: _passwordController,
                          validator: AppValidators.password,
                          obscureText: true,
                        ),
                        SizedBox(height: 24),
                        AuthInputWidget(
                          readOnly: !canEditPassword,
                          hint: 'Enter password',
                          label: 'New password',
                          isPassword: true,
                          controller: _newPasswordController,
                          validator: AppValidators.password,
                          obscureText: true,
                        ),
                        SizedBox(height: 24),
                        AuthInputWidget(
                          readOnly: !canEditPassword,
                          hint: 'Enter password',
                          label: 'Confirm new password',
                          isPassword: true,
                          controller: _newConfirmPasswordController,
                          validator: AppValidators.password,
                          obscureText: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

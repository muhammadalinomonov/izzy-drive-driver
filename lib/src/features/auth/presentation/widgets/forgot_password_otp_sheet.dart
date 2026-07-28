import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otp_pin_field/otp_pin_field.dart';
import 'package:taxi_app/src/core/components/app_snack_bar.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';
import 'package:taxi_app/src/core/localization/locale_keys.g.dart';
import 'package:taxi_app/src/core/widgets/app_button.dart';
import 'package:taxi_app/src/features/auth/presentation/bloc/bloc/auth_bloc.dart';
import 'package:taxi_app/src/features/auth/presentation/bloc/forgot_password_bloc/forgot_password_bloc.dart';

Future<String?> showForgotPasswordOtpSheet(BuildContext context) {
  final bloc = context.read<ForgotPasswordBloc>();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) {
      return BlocProvider.value(
        value: bloc,
        child: const _ForgotPasswordOtpSheet(),
      );
    },
  );
}

class _ForgotPasswordOtpSheet extends StatefulWidget {
  const _ForgotPasswordOtpSheet();

  @override
  State<_ForgotPasswordOtpSheet> createState() =>
      _ForgotPasswordOtpSheetState();
}

class _ForgotPasswordOtpSheetState extends State<_ForgotPasswordOtpSheet> {
  Timer? _resendTimer;
  int _secondsLeft = 0;
  int _resetCounter = 0;
  String _otp = '';

  void _safePop(String? result) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop(result);
    });
  }

  @override
  void initState() {
    super.initState();
    _startTimer(context.read<ForgotPasswordBloc>().state.resendAfter);
  }

  void _startTimer(int seconds) {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = seconds);
    if (seconds <= 0) return;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
      listenWhen: (p, c) =>
          p.requestOtpStatus != c.requestOtpStatus ||
          p.verifyOtpStatus != c.verifyOtpStatus,
      listener: (context, state) {
        if (state.requestOtpStatus == AuthStatus.success &&
            state.resendAfter > 0 &&
            _secondsLeft == 0) {
          _startTimer(state.resendAfter);
        }
        if (state.verifyOtpStatus == AuthStatus.success) {
          _safePop(state.resetToken);
        } else if (state.verifyOtpStatus == AuthStatus.failure) {
          setState(() {
            _otp = '';
            _resetCounter += 1;
          });
          AppSnackBar.showError(context, state.errorMessage);
          if (state.errorCode == 'otp_expired' ||
              state.errorCode == 'otp_too_many_attempts') {
            _safePop(null);
          }
        }
      },
      builder: (context, state) {
        final email = state.email;
        final isVerifying = state.verifyOtpStatus == AuthStatus.loading;
        final isResending = state.requestOtpStatus == AuthStatus.loading;

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColor.lightGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Icon(Icons.email_outlined,
                    size: 46, color: AppColor.kPrimaryColor),
                const SizedBox(height: 14),
                Text(
                  LocaleKeys.auth_otp_enterCodeTitle.tr(),
                  style: context.textS.titleLarge!.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  LocaleKeys.auth_otp_sentTo.tr(namedArgs: {'email': email}),
                  textAlign: TextAlign.center,
                  style: context.textS.bodySmall!.copyWith(
                    color: AppColor.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                OtpPinField(
                  key: ValueKey('forgot-otp-$_resetCounter'),
                  maxLength: 6,
                  fieldWidth: 44,
                  fieldHeight: 48,
                  keyboardType: TextInputType.number,
                  otpPinFieldStyle: OtpPinFieldStyle(
                    defaultFieldBorderColor: AppColor.lightGrey,
                    activeFieldBorderColor: AppColor.kPrimaryColor,
                    filledFieldBorderColor: AppColor.kPrimaryColor,
                    fieldBorderRadius: 10,
                  ),
                  onChange: (value) => setState(() => _otp = value),
                  onCodeChanged: (value) => setState(() => _otp = value),
                  onSubmit: (value) => setState(() => _otp = value),
                ),
                const SizedBox(height: 16),
                _ResendRow(
                  secondsLeft: _secondsLeft,
                  isLoading: isResending,
                  onResend: () {
                    context.read<ForgotPasswordBloc>().add(
                          ResendForgotOtpEvent(
                            onError: () => AppSnackBar.showError(
                              context,
                              LocaleKeys.auth_otp_resendFailed.tr(),
                            ),
                          ),
                        );
                  },
                ),
                const SizedBox(height: 16),
                AppButton(
                  title: LocaleKeys.auth_otp_confirm.tr(),
                  isLoading: isVerifying,
                  onTap: () {
                    if (_otp.length != 6 || isVerifying) return;
                    FocusManager.instance.primaryFocus?.unfocus();
                    context.read<ForgotPasswordBloc>().add(
                          VerifyForgotOtpEvent(
                            otp: _otp,
                            onSuccess: (_) {},
                            onError: () {},
                          ),
                        );
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed:
                      isVerifying ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    LocaleKeys.auth_otp_cancel.tr(),
                    style: context.textS.bodySmall!.copyWith(
                      color: AppColor.grey,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResendRow extends StatelessWidget {
  const _ResendRow({
    required this.secondsLeft,
    required this.isLoading,
    required this.onResend,
  });

  final int secondsLeft;
  final bool isLoading;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final canResend = secondsLeft <= 0 && !isLoading;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          LocaleKeys.auth_otp_didntReceive.tr(),
          style: context.textS.bodySmall!.copyWith(
            color: AppColor.grey,
            fontSize: 13,
          ),
        ),
        if (isLoading)
          const SizedBox(
            width: 14,
            height: 14,
            child: CupertinoActivityIndicator(),
          )
        else
          GestureDetector(
            onTap: canResend ? onResend : null,
            child: Text(
              canResend
                  ? LocaleKeys.auth_otp_resend.tr()
                  : LocaleKeys.auth_otp_resendIn.tr(
                      namedArgs: {'seconds': secondsLeft.toString()},
                    ),
              style: context.textS.titleSmall!.copyWith(
                color: canResend ? AppColor.kPrimaryColor : AppColor.grey,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

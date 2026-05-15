import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:otp_pin_field/otp_pin_field.dart';
import 'package:taxi_app/src/core/components/app_snack_bar.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/extensions/text_style_extension.dart';
import 'package:taxi_app/src/core/localization/locale_keys.g.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';
import 'package:taxi_app/src/core/widgets/app_button.dart';
import 'package:taxi_app/src/features/phone_verify/presentation/bloc/phone_verify_bloc.dart';
import 'package:taxi_app/src/routes/pages.dart';

class PhoneOtpPage extends StatefulWidget {
  const PhoneOtpPage({super.key});

  @override
  State<PhoneOtpPage> createState() => _PhoneOtpPageState();
}

class _PhoneOtpPageState extends State<PhoneOtpPage> {
  Timer? _resendTimer;
  int _secondsLeft = 0;
  String _otp = '';

  @override
  void initState() {
    super.initState();
    _startTimer(context.read<PhoneVerifyBloc>().state.resendAfter);
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

  String get _maskedPhone {
    final s = context.read<PhoneVerifyBloc>().state;
    final raw = s.phoneNumber;
    final dial = s.dialCode;
    if (raw.isEmpty) return '';
    if (dial.isEmpty || !raw.startsWith(dial)) return raw;
    final number = raw.substring(dial.length);
    if (number.length < 2) return raw;
    final tail = number.substring(number.length - 2);
    return '$dial *** ** $tail';
  }

  void _onConfirm() {
    if (_otp.length != 6) return;
    FocusManager.instance.primaryFocus?.unfocus();
    context.read<PhoneVerifyBloc>().add(
      VerifyOtpEvent(
        otp: _otp,
        onSuccess: () {
          if (!mounted) return;
          // OTP page + bottom sheet ikkalasini birvarakayiga yopib,
          // ostidagi MainScreen'ga qaytamiz. context.go ishlatmaymiz —
          // u stack'ni butunlay almashtirardi va MainScreen.initState'ni
          // qaytadan ishga tushirardi (WS, FCM, OrdersBloc qayta yuklanardi).
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else {
            context.go(Pages.main);
          }
        },
        onError: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismisser(
      child: Scaffold(
        backgroundColor: AppColor.white,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: BlocBuilder<PhoneVerifyBloc, PhoneVerifyState>(
          builder: (context, state) {
            final isVerifying = state.verifyStatus == PhoneVerifyStatus.loading;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppButton(
                isLoading: isVerifying,
                title: LocaleKeys.phoneVerify_otp_confirm.tr(),
                onTap: _onConfirm,
              ),
            );
          },
        ),
        body: BlocConsumer<PhoneVerifyBloc, PhoneVerifyState>(
          listenWhen: (p, c) => p.sendStatus != c.sendStatus || p.verifyStatus != c.verifyStatus,
          listener: (context, state) {
            // Resend muvaffaqiyatli — timer'ni yangi resendAfter bilan boshlaymiz.
            if (state.sendStatus == PhoneVerifyStatus.success && state.resendAfter > 0 && _secondsLeft == 0) {
              _startTimer(state.resendAfter);
            }
            // Resend xato (cooldown, sms_service_not_configured, va h.k.) —
            // backend xabarini snackbar bilan ko'rsatamiz.
            if (state.sendStatus == PhoneVerifyStatus.failure) {
              AppSnackBar.showError(
                context,
                state.errorMessage.isEmpty
                    ? LocaleKeys.phoneVerify_otp_resendFailed.tr()
                    : state.errorMessage,
              );
            }
            // Verify xato — code'ga qarab harakat qilamiz.
            if (state.verifyStatus == PhoneVerifyStatus.failure) {
              final code = state.errorCode;
              if (code == 'otp_too_many_attempts' || code == 'otp_expired') {
                // Twilio'da verification yo'q yoki maks. urinishlar tugagan —
                // foydalanuvchi yangi kod so'rashi kerak. Sheet'ga qaytaramiz.
                AppSnackBar.showError(
                  context,
                  state.errorMessage.isEmpty
                      ? LocaleKeys.phoneVerify_otp_incorrect.tr()
                      : state.errorMessage,
                );
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              }
              // Aks holda (otp_invalid yoki tarmoq xatosi) — sahifada qolamiz,
              // boxlar qizil bo'lib turaveradi, error matn ko'rsatiladi.
            }
          },
          builder: (context, state) {
            final hasError = state.verifyStatus == PhoneVerifyStatus.failure;
            final isResending = state.sendStatus == PhoneVerifyStatus.loading;
            return SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OtpHeader(maskedPhone: _maskedPhone),
                  const SizedBox(height: 0),
                  Center(
                    child: Text(
                      LocaleKeys.phoneVerify_otp_writeCode.tr(),
                      style: context.textS.bodyMedium!.copyWith(
                        color: AppColor.grey,
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: OtpPinField(
                      maxLength: 6,
                      fieldWidth: 44,
                      fieldHeight: 48,
                      keyboardType: TextInputType.number,
                      otpPinFieldStyle: OtpPinFieldStyle(
                        defaultFieldBorderColor: hasError ? AppColor.red.withValues(alpha: 0.18) : AppColor.lightBlue,
                        activeFieldBorderColor: hasError ? AppColor.red.withValues(alpha: 0.4) : AppColor.kPrimaryColor,
                        filledFieldBorderColor: hasError ? AppColor.red.withValues(alpha: 0.4) : AppColor.lightBlue,
                        defaultFieldBackgroundColor: hasError ? AppColor.red.withValues(alpha: 0.08) : AppColor.lightBlue,
                        activeFieldBackgroundColor: hasError ? AppColor.red.withValues(alpha: 0.08) : AppColor.lightBlue,
                        filledFieldBackgroundColor: hasError ? AppColor.red.withValues(alpha: 0.08) : AppColor.lightBlue,
                        textStyle: TextStyle(
                          color: hasError ? AppColor.red : AppColor.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                        fieldBorderRadius: 10,
                        showHintText: true,
                        hintText: '0',
                        hintTextColor: AppColor.lightGreyBlue,
                      ),
                      onChange: (value) {
                        if (hasError) {
                          context.read<PhoneVerifyBloc>().add(const ClearOtpErrorEvent());
                        }
                        setState(() => _otp = value);
                      },
                      onCodeChanged: (value) => setState(() => _otp = value),
                      onSubmit: (value) => setState(() => _otp = value),
                    ),
                  ),
                  if (hasError) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          // Backend'dan kelgan localized message (masalan
                          // "Kod noto'g'ri"). Tarmoq xatosi bo'lsa lokal fallback.
                          state.errorMessage.isEmpty
                              ? LocaleKeys.phoneVerify_otp_incorrect.tr()
                              : state.errorMessage,
                          textAlign: TextAlign.center,
                          style: context.textS.bodySmall!
                              .copyWith(color: AppColor.red, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _ResendRow(
                    secondsLeft: _secondsLeft,
                    isLoading: isResending,
                    hasError: hasError,
                    onResend: () {
                      context.read<PhoneVerifyBloc>().add(
                        ResendOtpEvent(
                          onError: () => AppSnackBar.showError(context, LocaleKeys.phoneVerify_otp_resendFailed.tr()),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OtpHeader extends StatelessWidget {
  const _OtpHeader({required this.maskedPhone});

  final String maskedPhone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 280,
      child: Stack(
        children: [
          // Auth sahifalardagi bilan bir xil gradient: yon-bo'yi joylashgan
          // ikkita PNG. OTP header'i shu fonni meros qiladi.
          Positioned.fill(child: Image.asset('assets/images/app_bar_gradiend.png', fit: BoxFit.fill)),
          // Gradient pastga oq fonga yumshoq o'tadi — keyin OTP boxlar uchun
          // toza oq joy qoladi.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColor.white.withValues(alpha: 0.0),
                    AppColor.white.withValues(alpha: 0.0),
                    AppColor.white.withValues(alpha: 0.85),
                    AppColor.white,
                  ],
                  stops: const [0.0, 0.55, 0.88, 1.0],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: context.padding.top),
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColor.black,
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Image.asset('assets/images/mail_with_1_badge.png', width: 75, height: 60),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    LocaleKeys.phoneVerify_otp_title.tr(),
                    style: context.textS.headlineSmall!.copyWith(fontWeight: FontWeight.w700, fontSize: 24),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 24),
                  child: Text(
                    LocaleKeys.phoneVerify_otp_subtitle.tr(namedArgs: {'phone': maskedPhone}),
                    style: context.textS.bodyMedium!.copyWith(
                      color: AppColor.grey,
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResendRow extends StatelessWidget {
  const _ResendRow({
    required this.secondsLeft,
    required this.isLoading,
    required this.hasError,
    required this.onResend,
  });

  final int secondsLeft;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final canResend = secondsLeft <= 0 && !isLoading;
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!canResend && !hasError) ...[
            Text(
              LocaleKeys.phoneVerify_otp_didntReceive.tr(),
              style: context.textS.bodyMedium!.copyWith(
                color: AppColor.grey,
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (isLoading)
            const SizedBox(width: 14, height: 14, child: CupertinoActivityIndicator())
          else if (canResend || hasError)
            GestureDetector(
              onTap: onResend,
              child: Row(
                children: [
                  Icon(Icons.refresh_rounded, size: 18, color: AppColor.kPrimaryColor),
                  const SizedBox(width: 6),
                  Text(
                    LocaleKeys.phoneVerify_otp_resend.tr(),
                    style: context.textS.bodyMedium!.copyWith(
                      color: AppColor.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              _formatTime(secondsLeft),
              style: context.textS.bodyMedium!.copyWith(
                color: AppColor.black,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

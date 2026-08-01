part of 'phone_verify_bloc.dart';

enum PhoneVerifyStatus { initial, loading, success, failure }

class PhoneVerifyState extends Equatable {
  final PhoneVerifyStatus sendStatus;
  final PhoneVerifyStatus verifyStatus;
  // E.164 to'liq raqam (masalan, "+998901234567")
  final String phoneNumber;
  // Dial code maskalash uchun ("+998")
  final String dialCode;
  final int expiresIn;
  final int resendAfter;
  final String errorMessage;
  // Backend'dan kelgan xato kodi (otp_invalid, otp_expired, otp_too_many_attempts,
  // otp_resend_cooldown, phone_invalid, sms_service_not_configured, ...)
  final String? errorCode;

  const PhoneVerifyState({
    this.sendStatus = PhoneVerifyStatus.initial,
    this.verifyStatus = PhoneVerifyStatus.initial,
    this.phoneNumber = '',
    this.dialCode = '',
    this.expiresIn = 0,
    this.resendAfter = 0,
    this.errorMessage = '',
    this.errorCode,
  });

  PhoneVerifyState copyWith({
    PhoneVerifyStatus? sendStatus,
    PhoneVerifyStatus? verifyStatus,
    String? phoneNumber,
    String? dialCode,
    int? expiresIn,
    int? resendAfter,
    String? errorMessage,
    String? errorCode,
    bool clearErrorCode = false,
  }) {
    return PhoneVerifyState(
      sendStatus: sendStatus ?? this.sendStatus,
      verifyStatus: verifyStatus ?? this.verifyStatus,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dialCode: dialCode ?? this.dialCode,
      expiresIn: expiresIn ?? this.expiresIn,
      resendAfter: resendAfter ?? this.resendAfter,
      errorMessage: errorMessage ?? this.errorMessage,
      errorCode: clearErrorCode ? null : (errorCode ?? this.errorCode),
    );
  }

  @override
  List<Object?> get props => [
        sendStatus,
        verifyStatus,
        phoneNumber,
        dialCode,
        expiresIn,
        resendAfter,
        errorMessage,
        errorCode,
      ];
}

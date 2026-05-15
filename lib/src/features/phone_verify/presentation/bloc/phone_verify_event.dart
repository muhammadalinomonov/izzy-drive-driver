part of 'phone_verify_bloc.dart';

sealed class PhoneVerifyEvent extends Equatable {
  const PhoneVerifyEvent();

  @override
  List<Object> get props => [];
}

class SendOtpEvent extends PhoneVerifyEvent {
  // To'liq E.164 raqam: "+998901234567"
  final String phoneNumber;
  // Dial code ("+998") — UI'da masklash uchun.
  final String dialCode;
  final VoidCallback onSuccess;
  final VoidCallback onError;

  const SendOtpEvent({
    required this.phoneNumber,
    required this.dialCode,
    required this.onSuccess,
    required this.onError,
  });
}

class ResendOtpEvent extends PhoneVerifyEvent {
  final VoidCallback onError;

  const ResendOtpEvent({required this.onError});
}

class VerifyOtpEvent extends PhoneVerifyEvent {
  final String otp;
  final VoidCallback onSuccess;
  final VoidCallback onError;

  const VerifyOtpEvent({
    required this.otp,
    required this.onSuccess,
    required this.onError,
  });
}

class ClearOtpErrorEvent extends PhoneVerifyEvent {
  const ClearOtpErrorEvent();
}

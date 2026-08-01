part of 'forgot_password_bloc.dart';

sealed class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();

  @override
  List<Object> get props => [];
}

class RequestForgotOtpEvent extends ForgotPasswordEvent {
  final String email;
  final VoidCallback onSuccess;
  final VoidCallback onError;

  const RequestForgotOtpEvent({
    required this.email,
    required this.onSuccess,
    required this.onError,
  });
}

class ResendForgotOtpEvent extends ForgotPasswordEvent {
  final VoidCallback onError;

  const ResendForgotOtpEvent({required this.onError});
}

class VerifyForgotOtpEvent extends ForgotPasswordEvent {
  final String otp;
  final ValueChanged<String> onSuccess;
  final VoidCallback onError;

  const VerifyForgotOtpEvent({
    required this.otp,
    required this.onSuccess,
    required this.onError,
  });
}

class ResetPasswordEvent extends ForgotPasswordEvent {
  final String newPassword;
  final VoidCallback onSuccess;
  final VoidCallback onError;

  const ResetPasswordEvent({
    required this.newPassword,
    required this.onSuccess,
    required this.onError,
  });
}

class ResetForgotStateEvent extends ForgotPasswordEvent {
  const ResetForgotStateEvent();
}

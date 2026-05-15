part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginEvent extends AuthEvent {
  final AuthModel authModel;
  final VoidCallback onSuccess;
  final VoidCallback onError;

  const LoginEvent({
    required this.authModel,
    required this.onError,
    required this.onSuccess,
  });
}

class GoogleSignInEvent extends AuthEvent {
  final VoidCallback onSuccess;
  final VoidCallback onError;

  const GoogleSignInEvent({required this.onSuccess, required this.onError});
}

class AppleSignInEvent extends AuthEvent {
  final VoidCallback onSuccess;
  final VoidCallback onError;

  const AppleSignInEvent({required this.onSuccess, required this.onError});
}

class RequestOtpEvent extends AuthEvent {
  final String email;
  final String fullName;
  final String password;
  final VoidCallback onSuccess;
  final VoidCallback onError;

  const RequestOtpEvent({
    required this.email,
    required this.fullName,
    required this.password,
    required this.onSuccess,
    required this.onError,
  });
}

class ResendOtpEvent extends AuthEvent {
  final VoidCallback onError;

  const ResendOtpEvent({required this.onError});
}

class VerifyOtpEvent extends AuthEvent {
  final String otp;
  final VoidCallback onSuccess;
  final VoidCallback onError;

  const VerifyOtpEvent({
    required this.otp,
    required this.onSuccess,
    required this.onError,
  });
}

class ResetRegistrationEvent extends AuthEvent {
  const ResetRegistrationEvent();
}

class LogoutEvent extends AuthEvent {
  final VoidCallback onSuccess;
  final VoidCallback onError;

  const LogoutEvent({required this.onSuccess, required this.onError});
}

class DeleteAccountEvent extends AuthEvent {
  final VoidCallback onSuccess;
  final VoidCallback onError;

  const DeleteAccountEvent({required this.onSuccess, required this.onError});
}

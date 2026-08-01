part of 'forgot_password_bloc.dart';

class ForgotPasswordState extends Equatable {
  final AuthStatus requestOtpStatus;
  final AuthStatus verifyOtpStatus;
  final AuthStatus resetStatus;
  final String email;
  final String resetToken;
  final int expiresIn;
  final int resendAfter;
  final String errorMessage;
  final String? errorCode;

  const ForgotPasswordState({
    this.requestOtpStatus = AuthStatus.initial,
    this.verifyOtpStatus = AuthStatus.initial,
    this.resetStatus = AuthStatus.initial,
    this.email = '',
    this.resetToken = '',
    this.expiresIn = 0,
    this.resendAfter = 0,
    this.errorMessage = '',
    this.errorCode,
  });

  ForgotPasswordState copyWith({
    AuthStatus? requestOtpStatus,
    AuthStatus? verifyOtpStatus,
    AuthStatus? resetStatus,
    String? email,
    String? resetToken,
    int? expiresIn,
    int? resendAfter,
    String? errorMessage,
    String? errorCode,
  }) {
    return ForgotPasswordState(
      requestOtpStatus: requestOtpStatus ?? this.requestOtpStatus,
      verifyOtpStatus: verifyOtpStatus ?? this.verifyOtpStatus,
      resetStatus: resetStatus ?? this.resetStatus,
      email: email ?? this.email,
      resetToken: resetToken ?? this.resetToken,
      expiresIn: expiresIn ?? this.expiresIn,
      resendAfter: resendAfter ?? this.resendAfter,
      errorMessage: errorMessage ?? this.errorMessage,
      errorCode: errorCode ?? this.errorCode,
    );
  }

  @override
  List<Object?> get props => [
        requestOtpStatus,
        verifyOtpStatus,
        resetStatus,
        email,
        resetToken,
        expiresIn,
        resendAfter,
        errorMessage,
        errorCode,
      ];
}

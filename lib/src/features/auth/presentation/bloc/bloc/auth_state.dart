part of 'auth_bloc.dart';

enum AuthStatus { initial, loading, success, failure }

class AuthState extends Equatable {
  final AuthStatus loginStatus;
  final AuthStatus requestOtpStatus;
  final AuthStatus verifyOtpStatus;
  final AuthStatus googleStatus;
  final AuthStatus appleStatus;
  final AuthStatus logoutStatus;
  final AuthStatus deleteAccountStatus;
  final String email;
  final String fullName;
  final String password;
  final int resendAfter;
  final int expiresIn;
  final String? errorMessage;
  final String? errorCode;

  const AuthState({
    this.loginStatus = AuthStatus.initial,
    this.requestOtpStatus = AuthStatus.initial,
    this.verifyOtpStatus = AuthStatus.initial,
    this.googleStatus = AuthStatus.initial,
    this.appleStatus = AuthStatus.initial,
    this.logoutStatus = AuthStatus.initial,
    this.deleteAccountStatus = AuthStatus.initial,
    this.email = '',
    this.fullName = '',
    this.password = '',
    this.resendAfter = 0,
    this.expiresIn = 0,
    this.errorMessage,
    this.errorCode,
  });

  AuthStatus get status => loginStatus;

  AuthState copyWith({
    AuthStatus? loginStatus,
    AuthStatus? requestOtpStatus,
    AuthStatus? verifyOtpStatus,
    AuthStatus? googleStatus,
    AuthStatus? appleStatus,
    AuthStatus? logoutStatus,
    AuthStatus? deleteAccountStatus,
    String? email,
    String? fullName,
    String? password,
    int? resendAfter,
    int? expiresIn,
    String? errorMessage,
    String? errorCode,
  }) {
    return AuthState(
      loginStatus: loginStatus ?? this.loginStatus,
      requestOtpStatus: requestOtpStatus ?? this.requestOtpStatus,
      verifyOtpStatus: verifyOtpStatus ?? this.verifyOtpStatus,
      googleStatus: googleStatus ?? this.googleStatus,
      appleStatus: appleStatus ?? this.appleStatus,
      logoutStatus: logoutStatus ?? this.logoutStatus,
      deleteAccountStatus: deleteAccountStatus ?? this.deleteAccountStatus,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      password: password ?? this.password,
      resendAfter: resendAfter ?? this.resendAfter,
      expiresIn: expiresIn ?? this.expiresIn,
      errorMessage: errorMessage ?? this.errorMessage,
      errorCode: errorCode ?? this.errorCode,
    );
  }

  @override
  List<Object?> get props => [
        loginStatus,
        requestOtpStatus,
        verifyOtpStatus,
        googleStatus,
        appleStatus,
        logoutStatus,
        deleteAccountStatus,
        email,
        fullName,
        password,
        resendAfter,
        expiresIn,
        errorMessage,
        errorCode,
      ];
}

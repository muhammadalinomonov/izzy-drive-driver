part of 'auth_bloc.dart';

@immutable
class AuthState extends Equatable {
  final FormzSubmissionStatus registerStatus;
  final FormzSubmissionStatus loginStatus;
  final String errorMessage;

  const AuthState({
    this.registerStatus = FormzSubmissionStatus.initial,
    this.loginStatus = FormzSubmissionStatus.initial,
    this.errorMessage = '',
  });

  AuthState copyWith({
    FormzSubmissionStatus? registerStatus,
    FormzSubmissionStatus? loginStatus,
    String? errorMessage,
  }) {
    return AuthState(
      registerStatus: registerStatus ?? this.registerStatus,
      loginStatus: loginStatus ?? this.loginStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object> get props => [registerStatus, loginStatus, errorMessage];
}

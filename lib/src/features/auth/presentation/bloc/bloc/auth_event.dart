part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class RegisterEvent extends AuthEvent {
  final AuthModel authModel;
  final VoidCallback onSuccess;
  final VoidCallback onError;

  const RegisterEvent({
    required this.authModel,
    required this.onError,
    required this.onSuccess,
  });
}

class LoginEvent extends AuthEvent {
  final AuthModel authModel;
  const LoginEvent({required this.authModel});
}

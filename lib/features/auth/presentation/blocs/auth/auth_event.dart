part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

class RegisterUser extends AuthEvent{
  final String email;
  final String firstName;
  final String password;

  RegisterUser({
    required this.email,
    required this.firstName,
    required this.password,
  });
}

class LoginUser extends AuthEvent {
  final String username;
  final String password;

  LoginUser({
    required this.username,
    required this.password,
  });
}

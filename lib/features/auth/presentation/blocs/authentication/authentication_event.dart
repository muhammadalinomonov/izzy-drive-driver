part of 'authentication_bloc.dart';

@immutable
sealed class AuthenticationEvent {}


class AuthInitialEvent extends AuthenticationEvent {
}
class AuthenticationStatusChanged extends AuthenticationEvent {
  final AuthenticationStatus status;

  AuthenticationStatusChanged({required this.status});
}

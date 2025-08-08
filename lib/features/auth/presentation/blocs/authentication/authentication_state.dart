part of 'authentication_bloc.dart';

@immutable
class AuthenticationState extends Equatable {
  final AuthenticationStatus status;

  const AuthenticationState._({
    this.status = AuthenticationStatus.unauthenticated,
  });

  const AuthenticationState.authenticated()
      : this._(
          status: AuthenticationStatus.authenticated,
        );

  const AuthenticationState.unauthenticated() : this._();

  AuthenticationState copyWith({
    AuthenticationStatus? status,
  }) {
    return AuthenticationState._(
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        status,
      ];
}

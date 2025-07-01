import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:taxi_app/src/features/auth/data/model/auth_model.dart';
import 'package:taxi_app/src/features/auth/domain/repo/auth_repo.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepo authRepo;

  AuthBloc({required this.authRepo})
    : super(AuthState(status: AuthStatus.initial)) {
    on<RegisterEvent>((event, emit) async {
      emit(AuthState(status: AuthStatus.loading));
      final response = await authRepo.register(event.authModel);
      if (response.errorText.isEmpty) {
        event.onSuccess();
        emit(AuthState(status: AuthStatus.success));
      } else {
        event.onError();
        emit(
          AuthState(
            status: AuthStatus.failure,
            errorMessage: response.errorText,
          ),
        );
      }
    });
    on<LoginEvent>((event, emit) async {
      emit(AuthState(status: AuthStatus.loading));
      final response = await authRepo.logIn(event.authModel);
      if (response.errorText.isEmpty) {
        emit(AuthState(status: AuthStatus.success));
      } else {
        emit(
          AuthState(
            status: AuthStatus.failure,
            errorMessage: response.errorText,
          ),
        );
      }
    });
  }
}

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanic/core/usecases/use_case.dart';
import 'package:mechanic/core/utils/service_locator.dart';
import 'package:mechanic/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mechanic/features/auth/domain/usecases/auth_status_usecase.dart';
import 'package:mechanic/features/auth/domain/usecases/get_user_usecase.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  late StreamSubscription<AuthenticationStatus> _authSubscription;
  final GetAuthStatusUseCase _authStatusUseCase = GetAuthStatusUseCase(repository: serviceLocator.call());
  final GetUserDataUseCase _getUserDataUseCase = GetUserDataUseCase(repository: serviceLocator.call());

  AuthenticationBloc() : super(const AuthenticationState.unauthenticated()) {

    on<AuthInitialEvent>(_onInit);
    on<AuthenticationStatusChanged>(_onAuthenticationStatusChanged);
  }


  Future<void> _onInit(AuthInitialEvent event, Emitter<AuthenticationState> emit) async {
    print('AuthenticationBloc initialized');
    _authSubscription = _authStatusUseCase.call(NoParams()).listen((event) {
      print('AuthenticationBloc initialized2 $event');
      add(AuthenticationStatusChanged(status: event));
    });
  }

  void _onAuthenticationStatusChanged(AuthenticationStatusChanged event, Emitter<AuthenticationState> emit) async {
    emit(state.copyWith(status: event.status));
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}

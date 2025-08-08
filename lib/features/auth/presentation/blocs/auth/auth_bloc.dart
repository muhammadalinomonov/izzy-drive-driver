import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:mechanic/core/utils/notifications.dart';
import 'package:mechanic/core/utils/service_locator.dart';
import 'package:mechanic/features/auth/domain/usecases/login_usecase.dart';
import 'package:mechanic/features/auth/domain/usecases/register_usecase.dart';
import 'package:meta/meta.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RegisterUseCase _registerUseCase = RegisterUseCase(repository: serviceLocator.call());
  final LoginUseCase _loginUseCase = LoginUseCase(repository: serviceLocator.call());

  AuthBloc() : super(AuthState()) {
    on<RegisterUser>(_onRegisterUser);
    on<LoginUser>(_onLoginUser);
  }

  Future<void> _onRegisterUser(RegisterUser event, Emitter<AuthState> emit) async {
    emit(state.copyWith(registerStatus: FormzSubmissionStatus.inProgress));
    final fcmToken = await PushNotifications.getToken();
    final result = await _registerUseCase.call(
      (email: event.email, password: event.password, fullName: event.firstName, fcmToken: fcmToken),
    );

    if (result.isRight) {
      emit(state.copyWith(registerStatus: FormzSubmissionStatus.success));
    } else {
      emit(state.copyWith(
        registerStatus: FormzSubmissionStatus.failure,
        errorMessage: result.left.errorMessage,
      ));
    }
  }

  Future<void> _onLoginUser(LoginUser event, Emitter<AuthState> emit) async {
    emit(state.copyWith(loginStatus: FormzSubmissionStatus.inProgress));
    final result = await _loginUseCase.call((event.username, event.password));

    if (result.isRight) {
      emit(state.copyWith(loginStatus: FormzSubmissionStatus.success));
    } else {
      emit(state.copyWith(
        loginStatus: FormzSubmissionStatus.failure,
        errorMessage: result.left.errorMessage,
      ));
    }
  }
}

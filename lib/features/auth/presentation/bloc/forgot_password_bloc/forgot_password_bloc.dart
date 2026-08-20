import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:taxi_app/core/localization/locale_keys.g.dart';
import 'package:taxi_app/features/auth/domain/repo/auth_repo.dart';
import 'package:taxi_app/features/auth/presentation/bloc/bloc/auth_bloc.dart'
    show AuthStatus;

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

@injectable
class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  /// `'auth1'` — password reset only exists on the izzydrive side; both
  /// [AuthRepo] registrations are named now, so this must be qualified too.
  final AuthRepo authRepo;

  /// [seedResetToken] is supplied at call time, not resolved from the graph -
  /// it comes from the OTP screen the user just came through. Request via
  /// `getIt<ForgotPasswordBloc>(param1: token)`.
  ForgotPasswordBloc({
    @Named('auth1') required this.authRepo,
    @factoryParam String? seedResetToken,
  }) : super(ForgotPasswordState(resetToken: seedResetToken ?? '')) {
    on<RequestForgotOtpEvent>(_onRequestOtp);
    on<ResendForgotOtpEvent>(_onResendOtp);
    on<VerifyForgotOtpEvent>(_onVerifyOtp);
    on<ResetPasswordEvent>(_onResetPassword);
    on<ResetForgotStateEvent>(_onResetState);
  }

  Future<void> _onRequestOtp(
    RequestForgotOtpEvent event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(state.copyWith(
      requestOtpStatus: AuthStatus.loading,
      verifyOtpStatus: AuthStatus.initial,
      email: event.email,
      errorMessage: '',
      errorCode: null,
    ));
    final response = await authRepo.forgotRequestOtp(event.email);
    if (response.errorText.isEmpty && response.data != null) {
      emit(state.copyWith(
        requestOtpStatus: AuthStatus.success,
        expiresIn: response.data!.expiresIn,
        resendAfter: response.data!.resendAfter,
      ));
      event.onSuccess();
    } else {
      event.onError();
      emit(state.copyWith(
        requestOtpStatus: AuthStatus.failure,
        errorMessage: response.errorText,
      ));
    }
  }

  Future<void> _onResendOtp(
    ResendForgotOtpEvent event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    if (state.email.isEmpty) return;
    emit(state.copyWith(
      requestOtpStatus: AuthStatus.loading,
      errorMessage: '',
      errorCode: null,
    ));
    final response = await authRepo.forgotRequestOtp(state.email);
    if (response.errorText.isEmpty && response.data != null) {
      emit(state.copyWith(
        requestOtpStatus: AuthStatus.success,
        expiresIn: response.data!.expiresIn,
        resendAfter: response.data!.resendAfter,
      ));
    } else {
      event.onError();
      emit(state.copyWith(
        requestOtpStatus: AuthStatus.failure,
        errorMessage: response.errorText,
      ));
    }
  }

  Future<void> _onVerifyOtp(
    VerifyForgotOtpEvent event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(state.copyWith(
      verifyOtpStatus: AuthStatus.loading,
      errorMessage: '',
      errorCode: null,
    ));
    final response = await authRepo.forgotVerifyOtp(
      email: state.email,
      otp: event.otp,
    );
    if (response.errorText.isEmpty && response.data != null) {
      emit(state.copyWith(
        verifyOtpStatus: AuthStatus.success,
        resetToken: response.data,
      ));
      event.onSuccess(response.data!);
    } else {
      event.onError();
      emit(state.copyWith(
        verifyOtpStatus: AuthStatus.failure,
        errorMessage: response.errorText,
      ));
    }
  }

  Future<void> _onResetPassword(
    ResetPasswordEvent event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    if (state.resetToken.isEmpty) {
      event.onError();
      emit(state.copyWith(
        resetStatus: AuthStatus.failure,
        errorMessage: LocaleKeys.auth_errors_resetTokenMissing.tr(),
      ));
      return;
    }
    emit(state.copyWith(
      resetStatus: AuthStatus.loading,
      errorMessage: '',
      errorCode: null,
    ));
    final response = await authRepo.forgotReset(
      resetToken: state.resetToken,
      newPassword: event.newPassword,
    );
    if (response.errorText.isEmpty) {
      event.onSuccess();
      emit(state.copyWith(resetStatus: AuthStatus.success));
    } else {
      event.onError();
      emit(state.copyWith(
        resetStatus: AuthStatus.failure,
        errorMessage: response.errorText,
      ));
    }
  }

  void _onResetState(
    ResetForgotStateEvent event,
    Emitter<ForgotPasswordState> emit,
  ) {
    emit(const ForgotPasswordState());
  }
}

import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/core/network/auth_session.dart';
import 'package:taxi_app/core/network/token_service.dart';
import 'package:taxi_app/features/phone_verify/domain/repo/phone_verify_repo.dart';

part 'phone_verify_event.dart';
part 'phone_verify_state.dart';

@injectable
class PhoneVerifyBloc extends Bloc<PhoneVerifyEvent, PhoneVerifyState> {
  final PhoneVerifyRepo repo;

  PhoneVerifyBloc({required this.repo}) : super(const PhoneVerifyState()) {
    on<SendOtpEvent>(_onSendOtp);
    on<ResendOtpEvent>(_onResendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<ClearOtpErrorEvent>(_onClearOtpError);
  }

  Future<void> _onSendOtp(SendOtpEvent event, Emitter<PhoneVerifyState> emit) async {
    emit(state.copyWith(
      sendStatus: PhoneVerifyStatus.loading,
      verifyStatus: PhoneVerifyStatus.initial,
      phoneNumber: event.phoneNumber,
      dialCode: event.dialCode,
      errorMessage: '',
      clearErrorCode: true,
    ));
    final response = await repo.sendOtp(event.phoneNumber);
    if (response.errorText.isEmpty && response.data != null) {
      emit(state.copyWith(
        sendStatus: PhoneVerifyStatus.success,
        expiresIn: response.data!.expiresIn,
        resendAfter: response.data!.resendAfter,
      ));
      event.onSuccess();
    } else {
      emit(state.copyWith(
        sendStatus: PhoneVerifyStatus.failure,
        errorMessage: response.errorText,
        errorCode: response.errorCode,
      ));
      event.onError();
    }
  }

  Future<void> _onResendOtp(ResendOtpEvent event, Emitter<PhoneVerifyState> emit) async {
    if (state.phoneNumber.isEmpty) return;
    emit(state.copyWith(
      sendStatus: PhoneVerifyStatus.loading,
      errorMessage: '',
      clearErrorCode: true,
    ));
    final response = await repo.resendOtp(state.phoneNumber);
    if (response.errorText.isEmpty && response.data != null) {
      emit(state.copyWith(
        sendStatus: PhoneVerifyStatus.success,
        expiresIn: response.data!.expiresIn,
        resendAfter: response.data!.resendAfter,
      ));
    } else {
      emit(state.copyWith(
        sendStatus: PhoneVerifyStatus.failure,
        errorMessage: response.errorText,
        errorCode: response.errorCode,
      ));
      event.onError();
    }
  }

  Future<void> _onVerifyOtp(VerifyOtpEvent event, Emitter<PhoneVerifyState> emit) async {
    emit(state.copyWith(
      verifyStatus: PhoneVerifyStatus.loading,
      errorMessage: '',
      clearErrorCode: true,
    ));
    final response = await repo.verifyOtp(
      phoneNumber: state.phoneNumber,
      otp: event.otp,
    );
    if (response.errorText.isEmpty) {
      await StorageRepository.putBool(key: 'phone_verified', value: true);
      AuthSession.notifyAuthChanged();
      emit(state.copyWith(verifyStatus: PhoneVerifyStatus.success));
      event.onSuccess();
    } else {
      emit(state.copyWith(
        verifyStatus: PhoneVerifyStatus.failure,
        errorMessage: response.errorText,
        errorCode: response.errorCode,
      ));
      event.onError();
    }
  }

  void _onClearOtpError(ClearOtpErrorEvent event, Emitter<PhoneVerifyState> emit) {
    if (state.verifyStatus == PhoneVerifyStatus.failure) {
      emit(state.copyWith(
        verifyStatus: PhoneVerifyStatus.initial,
        errorMessage: '',
        clearErrorCode: true,
      ));
    }
  }
}

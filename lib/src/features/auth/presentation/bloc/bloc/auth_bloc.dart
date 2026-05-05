import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:taxi_app/src/core/localization/locale_keys.g.dart';
import 'package:taxi_app/src/core/utils/notifications.dart';
import 'package:taxi_app/src/features/auth/data/model/auth_model.dart';
import 'package:taxi_app/src/features/auth/domain/repo/auth_repo.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepo authRepo;

  AuthBloc({required this.authRepo}) : super(const AuthState()) {
    on<LoginEvent>(_onLogin);
    on<GoogleSignInEvent>(_onGoogleSignIn);
    on<AppleSignInEvent>(_onAppleSignIn);
    on<RequestOtpEvent>(_onRequestOtp);
    on<ResendOtpEvent>(_onResendOtp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<ResetRegistrationEvent>(_onResetRegistration);
    on<LogoutEvent>(_onLogout);
    on<DeleteAccountEvent>(_onDeleteAccount);
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(logoutStatus: AuthStatus.loading, errorMessage: ''));
    final response = await authRepo.logout();
    // Always treat as success client-side: tokens are cleared either way.
    event.onSuccess();
    emit(state.copyWith(
      logoutStatus: AuthStatus.success,
      errorMessage: response.errorText.isEmpty ? null : response.errorText,
    ));
  }

  Future<void> _onDeleteAccount(
    DeleteAccountEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      deleteAccountStatus: AuthStatus.loading,
      errorMessage: '',
    ));
    final response = await authRepo.deleteAccount();
    if (response.errorText.isEmpty) {
      event.onSuccess();
      emit(state.copyWith(deleteAccountStatus: AuthStatus.success));
    } else {
      event.onError();
      emit(state.copyWith(
        deleteAccountStatus: AuthStatus.failure,
        errorMessage: response.errorText,
      ));
    }
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(loginStatus: AuthStatus.loading, errorMessage: ''));
    final response = await authRepo.logIn(event.authModel);
    if (response.errorText.isEmpty) {
      event.onSuccess();
      emit(state.copyWith(loginStatus: AuthStatus.success));
    } else {
      event.onError();
      emit(state.copyWith(
        loginStatus: AuthStatus.failure,
        errorMessage: response.errorText,
      ));
    }
  }

  Future<void> _onGoogleSignIn(
    GoogleSignInEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(googleStatus: AuthStatus.loading, errorMessage: ''));

    final google = GoogleSignIn(
      serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
      scopes: const ['email', 'profile'],
    );

    try {
      await google.disconnect();
    } catch (_) {}
    try {
      await google.signOut();
    } catch (_) {}

    GoogleSignInAccount? account;
    try {
      account = await google.signIn();
    } catch (e) {
      event.onError();
      emit(state.copyWith(
        googleStatus: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
      return;
    }

    if (account == null) {
      emit(state.copyWith(googleStatus: AuthStatus.initial));
      return;
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      event.onError();
      emit(state.copyWith(
        googleStatus: AuthStatus.failure,
        errorMessage: LocaleKeys.auth_errors_googleTokenEmpty.tr(),
      ));
      return;
    }

    final response = await authRepo.socialGoogle(
      idToken: idToken,
      fcmToken: await PushNotifications.getToken(),
    );
    if (response.errorText.isEmpty) {
      event.onSuccess();
      emit(state.copyWith(googleStatus: AuthStatus.success));
    } else {
      event.onError();
      emit(state.copyWith(
        googleStatus: AuthStatus.failure,
        errorMessage: response.errorText,
      ));
    }
  }

  Future<void> _onAppleSignIn(
    AppleSignInEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(appleStatus: AuthStatus.loading, errorMessage: ''));

    AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        emit(state.copyWith(appleStatus: AuthStatus.initial));
        return;
      }
      event.onError();
      emit(state.copyWith(
        appleStatus: AuthStatus.failure,
        errorMessage: e.message,
      ));
      return;
    } catch (e) {
      event.onError();
      emit(state.copyWith(
        appleStatus: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
      return;
    }

    final identityToken = credential.identityToken;
    final authorizationCode = credential.authorizationCode;
    if (identityToken == null || identityToken.isEmpty) {
      event.onError();
      emit(state.copyWith(
        appleStatus: AuthStatus.failure,
        errorMessage: LocaleKeys.auth_errors_appleTokenEmpty.tr(),
      ));
      return;
    }

    final response = await authRepo.socialApple(
      identityToken: identityToken,
      authorizationCode: authorizationCode,
      fcmToken: await PushNotifications.getToken(),
      email: credential.email,
      firstName: credential.givenName,
      lastName: credential.familyName,
    );
    if (response.errorText.isEmpty) {
      event.onSuccess();
      emit(state.copyWith(appleStatus: AuthStatus.success));
    } else {
      event.onError();
      emit(state.copyWith(
        appleStatus: AuthStatus.failure,
        errorMessage: response.errorText,
      ));
    }
  }

  Future<void> _onRequestOtp(
    RequestOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      requestOtpStatus: AuthStatus.loading,
      verifyOtpStatus: AuthStatus.initial,
      email: event.email,
      fullName: event.fullName,
      password: event.password,
      errorMessage: '',
      errorCode: null,
    ));

    final response = await authRepo.requestOtp(event.email);
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
    ResendOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (state.email.isEmpty) return;
    emit(state.copyWith(
      requestOtpStatus: AuthStatus.loading,
      errorMessage: '',
      errorCode: null,
    ));
    final response = await authRepo.requestOtp(state.email);
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
    VerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      verifyOtpStatus: AuthStatus.loading,
      errorMessage: '',
      errorCode: null,
    ));

    final verifyResponse = await authRepo.verifyOtp(
      email: state.email,
      otp: event.otp,
    );
    if (verifyResponse.errorText.isNotEmpty || verifyResponse.data == null) {
      event.onError();
      emit(state.copyWith(
        verifyOtpStatus: AuthStatus.failure,
        errorMessage: verifyResponse.errorText,
      ));
      return;
    }

    final completeResponse = await authRepo.completeRegister(
      verificationToken: verifyResponse.data!,
      password: state.password,
      fullName: state.fullName,
      fcmToken: await PushNotifications.getToken(),
    );
    if (completeResponse.errorText.isEmpty) {
      event.onSuccess();
      emit(state.copyWith(verifyOtpStatus: AuthStatus.success));
    } else {
      event.onError();
      emit(state.copyWith(
        verifyOtpStatus: AuthStatus.failure,
        errorMessage: completeResponse.errorText,
      ));
    }
  }

  void _onResetRegistration(
    ResetRegistrationEvent event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(
      requestOtpStatus: AuthStatus.initial,
      verifyOtpStatus: AuthStatus.initial,
      email: '',
      fullName: '',
      password: '',
      expiresIn: 0,
      resendAfter: 0,
      errorMessage: '',
      errorCode: null,
    ));
  }
}

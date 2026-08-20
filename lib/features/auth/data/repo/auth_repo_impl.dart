import 'package:injectable/injectable.dart';
import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/auth/data/model/auth_model.dart';
import 'package:taxi_app/features/auth/data/model/request_otp_model.dart';
import 'package:taxi_app/features/auth/data/source/auth_data_source.dart';
import 'package:taxi_app/features/auth/domain/repo/auth_repo.dart';

/// Named `'auth1'` - the izzydrive session. Registered alongside
/// [AuthRepoImpl2] (`'auth2'`) under the same [AuthRepo] type so `AuthBloc`
/// can hold both and switch between them by name instead of by type.
@Named('auth1')
@LazySingleton(as: AuthRepo)
class AuthRepoImpl extends AuthRepo {
  final AuthDataSource authDataSource;

  AuthRepoImpl({required this.authDataSource});

  @override
  Future<NetworkResponse> logIn(AuthModel authModel) =>
      authDataSource.logIn(authModel);

  @override
  Future<NetworkResponse> register(AuthModel authModel) =>
      authDataSource.register(authModel);

  @override
  Future<NetworkResponse<RequestOtpModel>> requestOtp(String email) =>
      authDataSource.requestOtp(email);

  @override
  Future<NetworkResponse<String>> verifyOtp({
    required String email,
    required String otp,
  }) =>
      authDataSource.verifyOtp(email: email, otp: otp);

  @override
  Future<NetworkResponse> completeRegister({
    required String verificationToken,
    required String password,
    required String fullName,
    required String fcmToken,
  }) =>
      authDataSource.completeRegister(
        verificationToken: verificationToken,
        password: password,
        fullName: fullName,
        fcmToken: fcmToken,
      );

  @override
  Future<NetworkResponse> socialGoogle({
    required String idToken,
    required String fcmToken,
  }) =>
      authDataSource.socialGoogle(idToken: idToken, fcmToken: fcmToken);

  @override
  Future<NetworkResponse> socialApple({
    required String identityToken,
    required String authorizationCode,
    required String fcmToken,
    String? email,
    String? firstName,
    String? lastName,
  }) =>
      authDataSource.socialApple(
        identityToken: identityToken,
        authorizationCode: authorizationCode,
        fcmToken: fcmToken,
        email: email,
        firstName: firstName,
        lastName: lastName,
      );

  @override
  Future<NetworkResponse<RequestOtpModel>> forgotRequestOtp(String email) =>
      authDataSource.forgotRequestOtp(email);

  @override
  Future<NetworkResponse<String>> forgotVerifyOtp({
    required String email,
    required String otp,
  }) =>
      authDataSource.forgotVerifyOtp(email: email, otp: otp);

  @override
  Future<NetworkResponse> forgotReset({
    required String resetToken,
    required String newPassword,
  }) =>
      authDataSource.forgotReset(
        resetToken: resetToken,
        newPassword: newPassword,
      );

  @override
  Future<NetworkResponse> logout() => authDataSource.logout();

  @override
  Future<NetworkResponse> deleteAccount() => authDataSource.deleteAccount();
}

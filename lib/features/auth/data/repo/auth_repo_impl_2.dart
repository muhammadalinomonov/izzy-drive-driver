import 'package:injectable/injectable.dart';
import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/auth/data/model/auth_model.dart';
import 'package:taxi_app/features/auth/data/model/request_otp_model.dart';
import 'package:taxi_app/features/auth/data/source/auth2_data_source.dart';
import 'package:taxi_app/features/auth/domain/repo/auth_repo.dart';

/// Named `'auth2'` - the Quadrix toll session. Bound under [AuthRepo], the
/// same type [AuthRepoImpl] (`'auth1'`) is bound under, so `AuthBloc` asks
/// for an `AuthRepo` and the `@Named` on its constructor parameter alone
/// decides which backend it logs in against - no second static type, and no
/// call site changes when the name is switched.
@Named('auth2')
@LazySingleton(as: AuthRepo)
class AuthRepoImpl2 extends AuthRepo {
  final Auth2DataSource auth2DataSource;

  AuthRepoImpl2({required this.auth2DataSource});

  @override
  Future<NetworkResponse> logIn(AuthModel authModel) =>
      auth2DataSource.logIn(authModel);

  @override
  Future<NetworkResponse> logout() => auth2DataSource.logout();

  // Everything below has no counterpart on the Quadrix Tolling backend - it
  // has no registration, OTP or social-login flow of its own, and a token is
  // never refreshed, only re-issued by [logIn]. Left as no-ops purely to
  // satisfy the inherited [AuthRepo] contract; they delegate to nothing and
  // must never be called.

  @override
  Future<NetworkResponse> register(AuthModel authModel) async =>
      NetworkResponse();

  @override
  Future<NetworkResponse<RequestOtpModel>> requestOtp(String email) async =>
      NetworkResponse<RequestOtpModel>();

  @override
  Future<NetworkResponse<String>> verifyOtp({
    required String email,
    required String otp,
  }) async => NetworkResponse<String>();

  @override
  Future<NetworkResponse> completeRegister({
    required String verificationToken,
    required String password,
    required String fullName,
    required String fcmToken,
  }) async => NetworkResponse();

  @override
  Future<NetworkResponse> socialGoogle({
    required String idToken,
    required String fcmToken,
  }) async => NetworkResponse();

  @override
  Future<NetworkResponse> socialApple({
    required String identityToken,
    required String authorizationCode,
    required String fcmToken,
    String? email,
    String? firstName,
    String? lastName,
  }) async => NetworkResponse();

  @override
  Future<NetworkResponse<RequestOtpModel>> forgotRequestOtp(
    String email,
  ) async => NetworkResponse<RequestOtpModel>();

  @override
  Future<NetworkResponse<String>> forgotVerifyOtp({
    required String email,
    required String otp,
  }) async => NetworkResponse<String>();

  @override
  Future<NetworkResponse> forgotReset({
    required String resetToken,
    required String newPassword,
  }) async => NetworkResponse();

  @override
  Future<NetworkResponse> deleteAccount() async => NetworkResponse();
}

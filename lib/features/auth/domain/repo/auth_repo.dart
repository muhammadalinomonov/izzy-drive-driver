import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/auth/data/model/auth_model.dart';
import 'package:taxi_app/features/auth/data/model/request_otp_model.dart';

abstract class AuthRepo {
  Future<NetworkResponse> register(AuthModel authModel);
  Future<NetworkResponse> logIn(AuthModel authModel);

  Future<NetworkResponse<RequestOtpModel>> requestOtp(String email);
  Future<NetworkResponse<String>> verifyOtp({
    required String email,
    required String otp,
  });
  Future<NetworkResponse> completeRegister({
    required String verificationToken,
    required String password,
    required String fullName,
    required String fcmToken,
  });

  Future<NetworkResponse> socialGoogle({
    required String idToken,
    required String fcmToken,
  });
  Future<NetworkResponse> socialApple({
    required String identityToken,
    required String authorizationCode,
    required String fcmToken,
    String? email,
    String? firstName,
    String? lastName,
  });

  Future<NetworkResponse<RequestOtpModel>> forgotRequestOtp(String email);
  Future<NetworkResponse<String>> forgotVerifyOtp({
    required String email,
    required String otp,
  });
  Future<NetworkResponse> forgotReset({
    required String resetToken,
    required String newPassword,
  });

  Future<NetworkResponse> logout();
  Future<NetworkResponse> deleteAccount();
}

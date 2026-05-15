import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/features/phone_verify/data/model/send_otp_response.dart';

abstract class PhoneVerifyRepo {
  Future<NetworkResponse<SendOtpResponse>> sendOtp(String phoneNumber);
  Future<NetworkResponse<SendOtpResponse>> resendOtp(String phoneNumber);
  Future<NetworkResponse> verifyOtp({
    required String phoneNumber,
    required String otp,
  });
}

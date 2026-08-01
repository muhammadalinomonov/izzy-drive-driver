import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/phone_verify/data/model/send_otp_response.dart';
import 'package:taxi_app/features/phone_verify/data/source/phone_verify_data_source.dart';
import 'package:taxi_app/features/phone_verify/domain/repo/phone_verify_repo.dart';

class PhoneVerifyRepoImpl extends PhoneVerifyRepo {
  final PhoneVerifyDataSource dataSource;

  PhoneVerifyRepoImpl({required this.dataSource});

  @override
  Future<NetworkResponse<SendOtpResponse>> sendOtp(String phoneNumber) =>
      dataSource.sendOtp(phoneNumber);

  @override
  Future<NetworkResponse<SendOtpResponse>> resendOtp(String phoneNumber) =>
      dataSource.resendOtp(phoneNumber);

  @override
  Future<NetworkResponse> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) =>
      dataSource.verifyOtp(phoneNumber: phoneNumber, otp: otp);
}

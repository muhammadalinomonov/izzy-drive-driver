import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/extensions/status_code_extension.dart';
import 'package:taxi_app/src/core/network/api_constants.dart';
import 'package:taxi_app/src/core/network/dio_model.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/core/utils/json_safe.dart';
import 'package:taxi_app/src/features/phone_verify/data/model/send_otp_response.dart';

// Backend kontrakti (PHONE_OTP.md):
//   POST accounts/phone/request-otp/   { phone_number }
//   POST accounts/phone/verify-otp/    { phone_number, otp }
// Response shape: { status, message, data?, code? }
//
// Error code'lar:
//   - otp_resend_cooldown       (request-otp 400 - kuting)
//   - phone_invalid             (request-otp 400 - yaroqsiz raqam)
//   - sms_service_not_configured (request-otp 503)
//   - invalid_input             (verify-otp 400 - bo'sh maydon)
//   - otp_invalid               (verify-otp 400 - xato kod, yana urinish bor)
//   - otp_expired               (verify-otp 400 - verification topilmadi)
//   - otp_too_many_attempts     (verify-otp 400 - qayta request kerak)
class PhoneVerifyDataSource {
  final client = serviceLocator.get<DioSettings>().dio;

  Future<NetworkResponse<SendOtpResponse>> sendOtp(String phoneNumber) async {
    try {
      final response = await client.post(
        ApiConstants.phoneRequestOtp,
        data: {'phone_number': phoneNumber},
      );
      if (response.isSuccess) {
        final dataMap = toMap(response.data is Map ? response.data['data'] : null);
        return NetworkResponse<SendOtpResponse>(
          data: SendOtpResponse.fromJson(dataMap),
        );
      }
      return _bodyError<SendOtpResponse>(response);
    } on DioException catch (e) {
      return _dioError<SendOtpResponse>(e);
    } catch (e) {
      return NetworkResponse<SendOtpResponse>(errorText: e.toString());
    }
  }

  Future<NetworkResponse<SendOtpResponse>> resendOtp(String phoneNumber) {
    // Backend bir xil endpoint - cooldown serverda Redis orqali boshqariladi.
    return sendOtp(phoneNumber);
  }

  Future<NetworkResponse> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final response = await client.post(
        ApiConstants.phoneVerifyOtp,
        data: {'phone_number': phoneNumber, 'otp': otp},
      );
      if (response.isSuccess) {
        final dataMap = toMap(response.data is Map ? response.data['data'] : null);
        final verified = toBool(dataMap['is_verified']);
        if (verified) {
          return NetworkResponse(data: true);
        }
        // 200 OK lekin is_verified=false - kutilmagan vaziyat, xato sifatida ishlamiz.
        return NetworkResponse(errorText: 'OTP not verified', errorCode: 'otp_invalid');
      }
      return _bodyError(response);
    } on DioException catch (e) {
      return _dioError(e);
    } catch (e) {
      return NetworkResponse(errorText: e.toString());
    }
  }

  // 4xx/5xx javob keldi-yu, lekin dio throw qilmadi (validateStatus boshqacha bo'lsa).
  NetworkResponse<T> _bodyError<T>(Response response) {
    final data = response.data;
    String msg = response.statusMessage ?? '';
    String? code;
    if (data is Map) {
      final m = data['message'];
      if (m is String && m.isNotEmpty) msg = m;
      final c = data['code'];
      if (c is String && c.isNotEmpty) code = c;
    }
    if (msg.isEmpty) msg = 'Server error';
    return NetworkResponse<T>(errorText: msg, errorCode: code);
  }

  NetworkResponse<T> _dioError<T>(DioException e) {
    final data = e.response?.data;
    String msg = e.message ?? '';
    String? code;
    if (data is Map) {
      final m = data['message'];
      if (m is String && m.isNotEmpty) msg = m;
      final c = data['code'];
      if (c is String && c.isNotEmpty) code = c;
    } else if (data is String && data.isNotEmpty) {
      msg = data;
    }
    // Connection-level xatolar (no internet, timeout) uchun
    if (msg.isEmpty) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          msg = 'Connection timeout';
          break;
        case DioExceptionType.connectionError:
          msg = 'No internet connection';
          break;
        default:
          msg = 'Server error';
      }
    }
    return NetworkResponse<T>(errorText: msg, errorCode: code);
  }
}

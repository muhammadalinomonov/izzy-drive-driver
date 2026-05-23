import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:taxi_app/src/core/extensions/status_code_extension.dart';
import 'package:taxi_app/src/core/localization/locale_keys.g.dart';
import 'package:taxi_app/src/core/network/api_constants.dart';
import 'package:taxi_app/src/core/network/dio_model.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/core/utils/json_safe.dart';
import 'package:taxi_app/src/features/auth/data/model/auth_model.dart';
import 'package:taxi_app/src/features/auth/data/model/request_otp_model.dart';

class AuthDataSource {
  final client = serviceLocator.get<DioSettings>().dio;

  Future<NetworkResponse> register(AuthModel authModel) async {
    try {
      final response = await client.post(
        ApiConstants.register,
        data: authModel.toMap(),
      );

      if (response.isSuccess) {
        _persistTokens(response.data);
        print('Success on register');
        return NetworkResponse(data: response.data);
      } else {
        print('Error on else ${response.statusMessage}');
        return NetworkResponse(errorText: response.statusMessage ?? "");
      }
    } on DioException catch (e) {
      print('Error on catch ${e.response?.data}');
      return NetworkResponse(errorText: _dioMessage(e));
    } catch (e) {
      print('Error on catchcatch ${e.toString()}');
      return NetworkResponse(errorText: e.toString());
    }
  }

  Future<NetworkResponse> logIn(AuthModel authModel) async {
    try {
      final response = await client.post(
        ApiConstants.login,
        data: authModel.toMap(),
      );

      if (response.isSuccess) {
        print('Success on login');
        print(response.data);
        _persistTokens(response.data);
        return NetworkResponse(data: response.data);
      } else {
        print('Log in error ${response.data}');
        return NetworkResponse(errorText: dioErrorMessage(response.data, response.statusMessage ?? ''));
      }
    } on DioException catch (e) {
      print('error on auth ${e.response?.data}');
      return NetworkResponse(errorText: _dioMessage(e));
    } catch (e) {
      return NetworkResponse(errorText: e.toString());
    }
  }

  Future<NetworkResponse<RequestOtpModel>> requestOtp(String email) async {
    try {
      final response = await client.post(
        ApiConstants.registerRequestOtp,
        data: {'email': email},
      );
      if (response.isSuccess) {
        final model = RequestOtpModel.fromJson(toMap(response.data['data']));
        return NetworkResponse<RequestOtpModel>(data: model);
      }
      return NetworkResponse<RequestOtpModel>(
        errorText: response.statusMessage ?? LocaleKeys.auth_errors_otpRequestFailed.tr(),
      );
    } on DioException catch (e) {
      return NetworkResponse<RequestOtpModel>(errorText: _dioMessage(e));
    } catch (e) {
      return NetworkResponse<RequestOtpModel>(errorText: e.toString());
    }
  }

  Future<NetworkResponse<String>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await client.post(
        ApiConstants.registerVerifyOtp,
        data: {'email': email, 'otp': otp},
      );
      if (response.isSuccess) {
        final token = toStrNullable(toMap(response.data['data'])['verification_token']);
        if (token == null || token.isEmpty) {
          return NetworkResponse<String>(errorText: LocaleKeys.auth_errors_verificationTokenEmpty.tr());
        }
        return NetworkResponse<String>(data: token);
      }
      return NetworkResponse<String>(
        errorText: response.statusMessage ?? LocaleKeys.auth_errors_otpVerifyFailed.tr(),
      );
    } on DioException catch (e) {
      return NetworkResponse<String>(errorText: _dioMessage(e));
    } catch (e) {
      return NetworkResponse<String>(errorText: e.toString());
    }
  }

  Future<NetworkResponse> completeRegister({
    required String verificationToken,
    required String password,
    required String fullName,
    required String fcmToken,
  }) async {
    try {
      final response = await client.post(
        ApiConstants.registerComplete,
        data: {
          'verification_token': verificationToken,
          'password': password,
          'full_name': fullName,
          'is_driver': true,
          'is_mechanic': false,
          'device_token': fcmToken,
        },
      );
      if (response.isSuccess) {
        _persistTokens(response.data);
        return NetworkResponse(data: response.data);
      }
      return NetworkResponse(
        errorText: response.statusMessage ?? LocaleKeys.auth_errors_registerFailed.tr(),
      );
    } on DioException catch (e) {
      return NetworkResponse(errorText: _dioMessage(e));
    } catch (e) {
      return NetworkResponse(errorText: e.toString());
    }
  }

  Future<NetworkResponse> socialGoogle({
    required String idToken,
    required String fcmToken,
  }) async {
    try {
      final response = await client.post(
        ApiConstants.registerGoogle,
        data: {
          'id_token': idToken,
          'is_driver': true,
          'is_mechanic': false,
          'device_token': fcmToken,
        },
      );
      if (response.isSuccess) {
        _persistTokens(response.data);
        return NetworkResponse(data: response.data);
      }
      return NetworkResponse(
        errorText: response.statusMessage ?? LocaleKeys.auth_errors_googleSignInFailed.tr(),
      );
    } on DioException catch (e) {
      return NetworkResponse(errorText: _dioMessage(e));
    } catch (e) {
      return NetworkResponse(errorText: e.toString());
    }
  }

  Future<NetworkResponse> socialApple({
    required String identityToken,
    required String authorizationCode,
    required String fcmToken,
    String? email,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final body = <String, dynamic>{
        'identity_token': identityToken,
        'authorization_code': authorizationCode,
        'is_driver': true,
        'is_mechanic': false,
        'device_token': fcmToken,
      };
      if (firstName != null && lastName != null) {
        body['user'] = {
          'email': email ?? '',
          'name': {
            'firstName': firstName,
            'lastName': lastName,
          },
        };
      }
      final response = await client.post(
        ApiConstants.registerApple,
        data: body,
      );
      if (response.isSuccess) {
        _persistTokens(response.data);
        return NetworkResponse(data: response.data);
      }
      print('Apple sign-in non-2xx response: ${response.statusCode} ${response.data}');
      return NetworkResponse(
        errorText: response.statusMessage ?? LocaleKeys.auth_errors_appleSignInFailed.tr(),
      );
    } on DioException catch (e) {
      print('Apple sign-in DioException: status=${e.response?.statusCode} data=${e.response?.data}');
      return NetworkResponse(errorText: _dioMessage(e));
    } catch (e) {
      print('Apple sign-in unexpected error: $e');
      return NetworkResponse(errorText: e.toString());
    }
  }

  Future<NetworkResponse<RequestOtpModel>> forgotRequestOtp(String email) async {
    try {
      final response = await client.post(
        ApiConstants.forgotRequestOtp,
        data: {'email': email},
      );
      if (response.isSuccess) {
        final model = RequestOtpModel.fromJson(toMap(response.data['data']));
        return NetworkResponse<RequestOtpModel>(data: model);
      }
      return NetworkResponse<RequestOtpModel>(
        errorText: response.statusMessage ?? LocaleKeys.auth_errors_otpRequestFailed.tr(),
      );
    } on DioException catch (e) {
      return NetworkResponse<RequestOtpModel>(errorText: _dioMessage(e));
    } catch (e) {
      return NetworkResponse<RequestOtpModel>(errorText: e.toString());
    }
  }

  Future<NetworkResponse<String>> forgotVerifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await client.post(
        ApiConstants.forgotVerifyOtp,
        data: {'email': email, 'otp': otp},
      );
      if (response.isSuccess) {
        final token = toStrNullable(toMap(response.data['data'])['reset_token']);
        if (token == null || token.isEmpty) {
          return NetworkResponse<String>(errorText: LocaleKeys.auth_errors_resetTokenMissing.tr());
        }
        return NetworkResponse<String>(data: token);
      }
      return NetworkResponse<String>(
        errorText: response.statusMessage ?? LocaleKeys.auth_errors_otpVerifyFailed.tr(),
      );
    } on DioException catch (e) {
      return NetworkResponse<String>(errorText: _dioMessage(e));
    } catch (e) {
      return NetworkResponse<String>(errorText: e.toString());
    }
  }

  Future<NetworkResponse> forgotReset({
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final response = await client.post(
        ApiConstants.forgotReset,
        data: {
          'reset_token': resetToken,
          'new_password': newPassword,
        },
      );
      if (response.isSuccess) {
        return NetworkResponse(data: response.data);
      }
      return NetworkResponse(
        errorText: response.statusMessage ?? LocaleKeys.auth_errors_passwordUpdateFailed.tr(),
      );
    } on DioException catch (e) {
      return NetworkResponse(errorText: _dioMessage(e));
    } catch (e) {
      return NetworkResponse(errorText: e.toString());
    }
  }

  Future<NetworkResponse> logout() async {
    try {
      final refresh = StorageRepository.getString('refresh');
      final response = await client.post(
        ApiConstants.logout,
        data: refresh.isEmpty ? null : {'refresh': refresh},
      );
      _clearTokens();
      if (response.isSuccess) {
        return NetworkResponse(data: response.data);
      }
      return NetworkResponse(
        errorText: response.statusMessage ?? LocaleKeys.auth_errors_logoutFailed.tr(),
      );
    } on DioException catch (e) {
      _clearTokens();
      return NetworkResponse(errorText: _dioMessage(e));
    } catch (e) {
      _clearTokens();
      return NetworkResponse(errorText: e.toString());
    }
  }

  Future<NetworkResponse> deleteAccount() async {
    try {
      final refresh = StorageRepository.getString('refresh');
      final response = await client.delete(
        ApiConstants.deleteAccount,
        data: refresh.isEmpty ? null : {'refresh': refresh},
      );
      if (response.isSuccess) {
        _clearTokens();
        return NetworkResponse(data: response.data);
      }
      return NetworkResponse(
        errorText: response.statusMessage ?? LocaleKeys.auth_errors_accountDeleteFailed.tr(),
      );
    } on DioException catch (e) {
      return NetworkResponse(errorText: _dioMessage(e));
    } catch (e) {
      return NetworkResponse(errorText: e.toString());
    }
  }

  void _clearTokens() {
    StorageRepository.deleteString('token');
    StorageRepository.deleteString('refresh');
    StorageRepository.deleteString('responseID');
  }

  void _persistTokens(dynamic responseData) {
    final dataMap = responseData is Map ? toMap(responseData['data']) : <String, dynamic>{};
    final access = dataMap['access'];
    final refresh = dataMap['refresh'];
    final id = dataMap['id'];
    if (access is String && access.isNotEmpty) StorageRepository.putString('token', access);
    if (refresh is String && refresh.isNotEmpty) StorageRepository.putString('refresh', refresh);
    if (id != null) StorageRepository.putString('responseID', id.toString());
    // Har bir yangi login - phone_verified cache'ni tozalaymiz. MainScreen
    // get-me orqali yangi user uchun haqiqiy holatni qaytadan aniqlaydi.
    // Token refresh (dio interceptor ichida) _persistTokens'ni chaqirmaydi,
    // shuning uchun mavjud sessiya buzilmaydi.
    StorageRepository.deleteBool('phone_verified');
  }

  String _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final m = data['message'];
      if (m is String && m.isNotEmpty) return m;
    }
    if (data is String && data.isNotEmpty) return data;
    return e.message ?? LocaleKeys.auth_errors_serverError.tr();
  }
}

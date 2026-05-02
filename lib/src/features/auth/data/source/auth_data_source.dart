import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/extensions/status_code_extension.dart';
import 'package:taxi_app/src/core/network/api_constants.dart';
import 'package:taxi_app/src/core/network/dio_model.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/core/service_locater.dart';
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
        final responseData = response.data['data']['access'];
        final responseID = response.data['data']['id'].toString();
        print('Success on register');
        StorageRepository.putString('responseID', responseID.toString().toString());
        StorageRepository.putString('token', responseData);
        StorageRepository.putString(
          'refresh',
          response.data['data']['refresh'],
        );
        return NetworkResponse(data: response.data);
      } else {
        print('Error on else ${response.statusMessage}');
        return NetworkResponse(errorText: response.statusMessage ?? "");
      }
    } on DioException catch (e) {
      print('Error on catch ${e.response?.data}');
      return NetworkResponse(
        errorText: e.response?.data.runtimeType == String ? 'Server is down and not working' : e.response?.data['message'] ?? 'Dio exception error',
      );
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
        final responseData = response.data['data']['access'];
        final responseID = response.data['data']['id'].toString();
        StorageRepository.putString('token', responseData);
        StorageRepository.putString('responseID', responseID);
        StorageRepository.putString(
          'refresh',
          response.data['data']['refresh'],
        );
        return NetworkResponse(data: response.data);
      } else {
        print('Log in error ${response.data}');
        return NetworkResponse(
          errorText: response.data['non_field_errors'].toString(),
        );
      }
    } on DioException catch (e) {
      print('error on auth ${e.response?.data['message']}');
      return NetworkResponse(
        errorText:
            e.response?.data['message'] ?? 'Dio exception error',
      );
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
        final model = RequestOtpModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        return NetworkResponse<RequestOtpModel>(data: model);
      }
      return NetworkResponse<RequestOtpModel>(
        errorText: response.statusMessage ?? 'OTP yuborib bo\'lmadi',
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
        final token = response.data['data']?['verification_token'] as String?;
        if (token == null || token.isEmpty) {
          return NetworkResponse<String>(errorText: 'verification_token bo\'sh');
        }
        return NetworkResponse<String>(data: token);
      }
      return NetworkResponse<String>(
        errorText: response.statusMessage ?? 'OTP tasdiqlanmadi',
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
        errorText: response.statusMessage ?? 'Ro\'yxatdan o\'tib bo\'lmadi',
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
        errorText: response.statusMessage ?? 'Google orqali kirib bo\'lmadi',
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
      return NetworkResponse(
        errorText: response.statusMessage ?? 'Apple orqali kirib bo\'lmadi',
      );
    } on DioException catch (e) {
      return NetworkResponse(errorText: _dioMessage(e));
    } catch (e) {
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
        final model = RequestOtpModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        return NetworkResponse<RequestOtpModel>(data: model);
      }
      return NetworkResponse<RequestOtpModel>(
        errorText: response.statusMessage ?? 'OTP yuborib bo\'lmadi',
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
        final token = response.data['data']?['reset_token'] as String?;
        if (token == null || token.isEmpty) {
          return NetworkResponse<String>(errorText: 'reset_token bo\'sh');
        }
        return NetworkResponse<String>(data: token);
      }
      return NetworkResponse<String>(
        errorText: response.statusMessage ?? 'OTP tasdiqlanmadi',
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
        errorText: response.statusMessage ?? 'Parolni yangilab bo\'lmadi',
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
        errorText: response.statusMessage ?? 'Tizimdan chiqib bo\'lmadi',
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
        errorText: response.statusMessage ?? 'Akkauntni o\'chirib bo\'lmadi',
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
    final access = responseData['data']?['access'];
    final refresh = responseData['data']?['refresh'];
    final id = responseData['data']?['id']?.toString();
    if (access is String) StorageRepository.putString('token', access);
    if (refresh is String) StorageRepository.putString('refresh', refresh);
    if (id != null) StorageRepository.putString('responseID', id);
  }

  String _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final m = data['message'];
      if (m is String && m.isNotEmpty) return m;
    }
    if (data is String && data.isNotEmpty) return data;
    return e.message ?? 'Server xatosi';
  }
}

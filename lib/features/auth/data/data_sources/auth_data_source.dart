import 'package:dio/dio.dart';
import 'package:mechanic/core/exceptions/exceptions.dart';
import 'package:mechanic/core/storage/storage_repository.dart';
import 'package:mechanic/core/storage/store_keys.dart';
import 'package:mechanic/features/auth/data/models/user_model.dart';
import 'package:mechanic/features/common/data/models/base_model.dart';

abstract class AuthDataSource {
  Future<void> register(
      {required String email, required String fullName, required String password, required String fcmToken});

  Future<BaseModel<UserModel>> getUserData();

  Future<String> login(String email, String password);

  Future<void> resendSms(String token);

  Future<UserModel> verifySms(String token, String code, String deviceName, String fcmToken, String deviceId);

  Future<void> fillInfo({required String name});

  Future<void> logout(String deviceId);
}

class AuthDataSourceImpl implements AuthDataSource {
  final Dio dio;

  AuthDataSourceImpl({required this.dio});

  @override
  Future<BaseModel<UserModel>> getUserData() async {
    try {
      final token = StorageRepository.getString(StoreKeys.token);
      final response = await dio.get(
        'mechanics/get-me/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        final user = BaseModel.fromJson(response.data, (json) => UserModel.fromJson(json));
        await StorageRepository.putInt(StoreKeys.wsId, user.data?.wsId ?? 0);
        return user;
      } else {
        throw ServerException(
            statusCode: response.statusCode ?? 500,
            errorMessage: response.data is String ? response.data : response.data);
      }
    } on DioException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ParsingException(errorMessage: e.toString());
    }
  }

  @override
  Future<String> login(String email, String password) async {
    try {
      final response = await dio.post('accounts/login/', data: {
        'email': email,
        'password': password,
      });
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        final access = response.data['data']['access'];
        final refresh = response.data['data']['refresh'];

        await StorageRepository.putString(StoreKeys.token, access);
        await StorageRepository.putString(StoreKeys.refresh, refresh);

        return access;
      } else {
        throw ServerException(
            statusCode: response.statusCode ?? 500,
            errorMessage: response.data is String ? response.data : response.data['message']);
      }
    } on DioException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ParsingException(errorMessage: e.toString());
    }
  }

  @override
  Future<void> resendSms(String token) async {
    try {
      final response = await dio.post('/api/client/auth/resend-sms', data: {
        'token': token,
      });
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return;
      } else {
        throw ServerException(
            statusCode: response.statusCode ?? 500,
            errorMessage: response.data is String ? response.data : response.data['message']);
      }
    } on DioException {
      rethrow;
    } on ServerException {
      rethrow;
    } on ParsingException {
      rethrow;
    } catch (e) {
      throw ParsingException(errorMessage: e.toString());
    }
  }

  @override
  Future<UserModel> verifySms(String token, String code, String deviceName, String fcmToken, String deviceId) async {
    try {
      final response = await dio.post('/api/client/auth/confirm-phone', data: {
        'token': token,
        'code': code,
        'device_name': deviceName,
        'fire_base_token': fcmToken,
        'device_id': deviceId,
      });
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        final user = UserModel.fromJson(response.data['data']);
        // await StorageRepository.putString(StoreKeys.token, user.authKey);
        return user;
      } else {
        throw ServerException(
            statusCode: response.statusCode ?? 500,
            errorMessage: response.data is String ? response.data : response.data['message']);
      }
    } on DioException {
      rethrow;
    } on ServerException catch (e) {
      rethrow;
    } on ParsingException {
      rethrow;
    } catch (e) {
      throw ParsingException(errorMessage: e.toString());
    }
  }

  @override
  Future<void> fillInfo({required String name}) async {
    try {
      final response = await dio.post('/api/client/auth/fill-user-account',
          data: {'first_name': name, 'last_name': '', 'born': '', 'gender': ''});
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return;
      } else {
        throw ServerException(
            statusCode: response.statusCode ?? 500,
            errorMessage: response.data is String ? response.data : response.data['message']);
      }
    } on DioException {
      rethrow;
    } on ServerException {
      rethrow;
    } on ParsingException {
      rethrow;
    } catch (e) {
      throw ParsingException(errorMessage: e.toString());
    }
  }

  @override
  Future<void> logout(String deviceId) async {
    try {
      final response = await dio.post('/api/client/user/log-out', queryParameters: {
        'deviceId': deviceId,
      });
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return;
      } else {
        throw ServerException(
            statusCode: response.statusCode ?? 500,
            errorMessage: response.data is String ? response.data : response.data['message']);
      }
    } on DioException {
      rethrow;
    } on ServerException {
      rethrow;
    } on ParsingException {
      rethrow;
    } catch (e) {
      throw ParsingException(errorMessage: e.toString());
    }
  }

  @override
  Future<void> register(
      {required String email, required String fullName, required String password, required String fcmToken}) async {
    try {
      final response = await dio.post('accounts/register/', data: {
        'email': email,
        'is_mechanic': false,
        'full_name': fullName,
        'password': password,
        'is_driver': true,
        'device_token': fcmToken
      });

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        await StorageRepository.putString(StoreKeys.token, response.data['data']['access']);
        await StorageRepository.putString(StoreKeys.refresh, response.data['data']['refresh']);
        return;
      } else {
        throw ServerException(
            statusCode: response.statusCode ?? 500,
            errorMessage: response.data is String ? response.data : response.data['message']);
      }
    } on DioException {
      rethrow;
    } on ServerException {
      rethrow;
    } on ParsingException {
      rethrow;
    } catch (e) {
      throw ParsingException(errorMessage: e.toString());
    }
  }
}

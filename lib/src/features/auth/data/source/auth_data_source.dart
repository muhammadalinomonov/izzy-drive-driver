import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/extensions/status_code_extension.dart';
import 'package:taxi_app/src/core/network/api_constants.dart';
import 'package:taxi_app/src/core/network/dio_model.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/features/auth/data/model/auth_model.dart';

class AuthDataSource {
  final client = serviceLocator.get<DioSettings>().dio;

  Future<NetworkResponse> register(AuthModel authModel) async {
    try {
      final response = await client.post(
        ApiConstants.register,
        data: authModel.toMap(),
      );

      if (response.isSuccess) {
        print('Success on register');
        print(response.data);
        return NetworkResponse(data: response.data);
      } else {
        return NetworkResponse(errorText: response.statusMessage ?? "");
      }
    } on DioException catch (e) {
      return NetworkResponse(
        errorText: e.response?.data ?? 'Dio exception error',
      );
    } catch (e) {
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
        return NetworkResponse(data: response.data);
      } else {
        return NetworkResponse(errorText: response.statusMessage ?? "");
      }
    } on DioException catch (e) {
      return NetworkResponse(
        errorText: e.response?.data ?? 'Dio exception error',
      );
    } catch (e) {
      return NetworkResponse(errorText: e.toString());
    }
  }
}

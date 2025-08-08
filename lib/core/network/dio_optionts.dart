import 'package:dio/dio.dart';
import 'package:mechanic/assets/constants/app_constants.dart';
import 'package:mechanic/core/network/auth_interceptor.dart';
import 'package:mechanic/core/network/token_refresh_interceptor.dart';

class DioOptions {
  final BaseOptions baseOptions = BaseOptions(
    baseUrl: AppConstants.BASE_URL_DEV,
    connectTimeout: const Duration(milliseconds: 35000),
    receiveTimeout: const Duration(milliseconds: 35000),
    followRedirects: false,
    validateStatus: (status) => status != null && status <= 500,
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );

  Dio get dio {
    final dio = Dio(baseOptions)
      ..interceptors.add(LogInterceptor(
        responseBody: true,
        requestBody: true,
        request: true,
        requestHeader: true,
      ))
      ..interceptors.add(AuthInterceptor())
      ..interceptors.add(TokenRefreshInterceptor());


    return dio;
  }
}

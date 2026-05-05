import 'dart:developer';

import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/network/auth_session.dart';
import 'package:taxi_app/src/core/network/token_service.dart';

class DioSettings {
  static final DioSettings _instance = DioSettings._internal();
  factory DioSettings() => _instance;
  late final Dio dio;

  DioSettings._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.izzydrive.com/api/v1/',
        headers: {'Content-Type': 'application/json', 'Accept-Language': 'en'},
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    dio.interceptors..add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print('Request sent: ${options.method} ${options.path}');
          options.headers['Accept'] = 'application/json';
          String? token = StorageRepository.getString('refresh');
          if (token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          print('Error caught: ${error.message}');
          if (error.response?.statusCode == 401 ||
              error.response?.statusCode == 403 &&
                  !error.requestOptions.path.contains('/accounts/refresh/')) {
            final refreshToken = StorageRepository.getString('refresh');
            if (refreshToken.isEmpty) {
              await AuthSession.clear();
              return handler.reject(error);
            }
            try {
              final response = await dio.post(
                '/accounts/refresh/',
                data: {'refresh_token': refreshToken},
              );
              final newAccessToken = response.data['data']['access'];
              final newRefreshToken = response.data['data']['refresh'];
              await StorageRepository.putString('token', newAccessToken);
              await StorageRepository.putString('refresh', newRefreshToken);
              AuthSession.notifyAuthChanged();

              error.requestOptions.headers['Authorization'] =
                  'Bearer $newAccessToken';
              final opts = Options(
                method: error.requestOptions.method,
                headers: error.requestOptions.headers,
              );
              final cloneReq = await dio.request(
                error.requestOptions.path,
                options: opts,
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
              );
              print(
                'Request cloned and sent again: ${error.requestOptions.method} ${error.requestOptions.path}',
              );
              return handler.resolve(cloneReq);
            } catch (e) {
              await AuthSession.clear();
              return handler.reject(error);
            }
          }
          return handler.next(error);
        },
      ),
    )..add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      logPrint: (obj) => log('$obj'),
      request: true,
      requestHeader: true,
      responseHeader: false,
    ));

    
      dio.interceptors.add(ChuckerDioInterceptor());
    
  }
}

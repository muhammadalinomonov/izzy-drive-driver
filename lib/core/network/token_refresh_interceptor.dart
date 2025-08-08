import 'dart:async';

import 'package:dio/dio.dart';
import 'package:mechanic/core/storage/storage_repository.dart';
import 'package:mechanic/core/storage/store_keys.dart';
import 'package:mechanic/features/auth/data/repositories/auth_repository_impl.dart';

typedef TokenStorage = Future<String?> Function();
typedef TokenSaver = Future<void> Function(String accessToken, String refreshToken);

class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (response.statusCode == 401 || response.statusCode == 403) {
      final refreshToken = StorageRepository.getString(StoreKeys.refresh);
      if (refreshToken.isEmpty) {
        handler.next(response);
        return;
      }

      await _refreshToken(response.requestOptions.baseUrl);
      final accessToken = StorageRepository.getString(StoreKeys.token);
      if (accessToken.isNotEmpty) {
        response.requestOptions.headers['Authorization'] = 'Bearer $accessToken';
      }

      final newResponse = await _resolveResponse(response.requestOptions);
      handler.resolve(newResponse);
    } else {
      handler.next(response); // Properly pass on the response
    }
  }

  Future<void> _refreshToken(String baseUrl) async {
    final refreshToken = StorageRepository.getString(StoreKeys.refresh);
    if (refreshToken.isNotEmpty) {
      try {
        final response = await Dio(BaseOptions(baseUrl: baseUrl)).post('accounts/refresh/', data: {
          'refresh': refreshToken,
        });
        if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
          await StorageRepository.putString(StoreKeys.token, '${response.data['access']}');
          // await StorageRepository.putString(StoreKeys.refresh, response.data['refresh_token']);
        } else {
          authStreamController.add(AuthenticationStatus.unauthenticated);
          await StorageRepository.deleteString(StoreKeys.refresh);
        }
      } catch (e) {
        authStreamController.add(AuthenticationStatus.unauthenticated);
        await StorageRepository.deleteString(StoreKeys.refresh);
        await StorageRepository.deleteString(StoreKeys.token);
      }
    }
  }

  Future<Response<dynamic>> _resolveResponse(RequestOptions options) async {
    final path = options.path;
    final baseUrl = options.baseUrl;
    try {
      return await Dio().request(
        baseUrl + path,
        options: Options(
          headers: options.headers,
          method: options.method,
        ),
      );
    } catch (e) {
      throw DioException(requestOptions: options, error: e.toString());
    }
  }
}

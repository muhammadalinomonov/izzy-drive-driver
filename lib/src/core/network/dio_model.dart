import 'dart:async';
import 'dart:developer';

import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/network/auth_session.dart';
import 'package:taxi_app/src/core/network/token_service.dart';

class DioSettings {
  static final DioSettings _instance = DioSettings._internal();
  factory DioSettings() => _instance;
  late final Dio dio;

  // Concurrent-refresh guard: parallel 401s converge on one refresh call
  // instead of stampeding the backend.
  Future<bool>? _refreshFuture;

  // Marks a request that was already retried once after a successful
  // refresh. If it 401s again, treat as a hard sign-out instead of
  // looping back into the refresh path.
  static const String _retriedFlag = 'token_refresh_retried';

  DioSettings._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.izzydrive.com/api/v1/',
        headers: {'Content-Type': 'application/json', 'Accept-Language': 'en'},
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    dio.interceptors
      ..add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.headers['Accept'] = 'application/json';
            final token = StorageRepository.getString('token');
            if (token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            handler.next(options);
          },
          onError: (error, handler) async {
            final status = error.response?.statusCode;
            // SimpleJWT returns 401 for expired/invalid tokens. 403 in
            // DRF usually means "authenticated but lacks permission" —
            // refreshing won't help, so we don't trigger refresh on it
            // (otherwise legitimate 403 endpoints kick the user out).
            final isAuthFailure = status == 401;
            final path = error.requestOptions.path;
            final isRefreshCall = path.contains('accounts/refresh/');
            final alreadyRetried =
                error.requestOptions.extra[_retriedFlag] == true;

            if (!isAuthFailure || isRefreshCall) {
              return handler.next(error);
            }
            if (alreadyRetried) {
              // Server still rejects after a successful refresh — give up.
              await AuthSession.clear();
              return handler.next(error);
            }

            final refreshToken = StorageRepository.getString('refresh');
            if (refreshToken.isEmpty) {
              await AuthSession.clear();
              return handler.reject(error);
            }

            final ok = await (_refreshFuture ??=
                _refreshToken().whenComplete(() {
              _refreshFuture = null;
            }));
            if (!ok) {
              return handler.reject(error);
            }

            final newAccess = StorageRepository.getString('token');
            if (newAccess.isEmpty) {
              return handler.reject(error);
            }

            try {
              final retryOptions = error.requestOptions
                ..headers['Authorization'] = 'Bearer $newAccess'
                ..extra[_retriedFlag] = true;
              final retry = await dio.fetch(retryOptions);
              return handler.resolve(retry);
            } on DioException catch (e) {
              return handler.reject(e);
            }
          },
        ),
      )
      ..add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => log('$obj'),
        request: true,
        requestHeader: true,
        responseHeader: false,
      ))
      ..add(ChuckerDioInterceptor());
  }

  /// Posts to `accounts/refresh/` (Simple JWT `TokenRefreshView`):
  ///   request:  `{ "refresh": "...refresh-token..." }`
  ///   response: `{ "access":  "...new-access-token..." }`   (rotation off)
  ///
  /// Uses a SEPARATE Dio with no interceptor so a 401 here can't loop
  /// back into onError above.
  Future<bool> _refreshToken() async {
    final refreshToken = StorageRepository.getString('refresh');
    if (refreshToken.isEmpty) return false;
    try {
      final freshDio = Dio(BaseOptions(
        baseUrl: 'https://api.izzydrive.com/api/v1/',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {'Content-Type': 'application/json'},
        validateStatus: (s) => s != null && s < 500,
      ));
      final response = await freshDio.post(
        'accounts/refresh/',
        data: {'refresh': refreshToken},
      );
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        final data = response.data;
        final access = data is Map ? data['access'] : null;
        if (access is String && access.isNotEmpty) {
          await StorageRepository.putString('token', access);
          AuthSession.notifyAuthChanged();
          return true;
        }
      }
    } catch (_) {
      // fall through to sign-out
    }
    await AuthSession.clear();
    return false;
  }
}

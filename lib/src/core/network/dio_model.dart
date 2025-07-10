import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/network/token_service.dart'; // Adjust import as needed
import 'package:taxi_app/src/features/auth/data/repo/auth_repo_impl.dart'; // Adjust import as needed

class DioSettings {
  static final DioSettings _instance = DioSettings._internal();
  factory DioSettings() => _instance;
  late final Dio dio;

  DioSettings._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://master-api.ataxi.uz/api/v1/',
        headers: {'Content-Type': 'application/json', 'Accept-Language': 'en'},
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['Accept'] = 'application/json';
          String? token = StorageRepository.getString('token');
          if (token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Prevent infinite loop by not refreshing on refresh endpoint
          if (error.response?.statusCode == 401 ||
              error.response?.statusCode == 403 &&
                  !error.requestOptions.path.contains('/accounts/refresh/')) {
            final refreshToken = StorageRepository.getString('refresh');
            if (refreshToken.isEmpty) {
              // Optionally: clear tokens, navigate to login, etc.
              await StorageRepository.deleteString('token');
              await StorageRepository.deleteString('refresh');
              return handler.reject(error);
            }
            try {
              // Call your refresh endpoint
              final response = await dio.post(
                '/accounts/refresh/',
                data: {'refresh_token': refreshToken},
              );
              final newAccessToken = response.data['data']['access'];
              final newRefreshToken = response.data['data']['refresh'];
              await StorageRepository.putString('token', newAccessToken);
              await StorageRepository.putString('refresh', newRefreshToken);

              // Update the failed request with new token and retry
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
              return handler.resolve(cloneReq);
            } catch (e) {
              // Refresh failed, clear tokens, optionally navigate to login
              await StorageRepository.deleteString('token');
              await StorageRepository.deleteString('refresh');
              return handler.reject(error);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }
}

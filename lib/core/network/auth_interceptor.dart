import 'package:mechanic/core/storage/storage_repository.dart';
import 'package:mechanic/core/storage/store_keys.dart';
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = StorageRepository.getString(StoreKeys.token);
    if (token.isNotEmpty && !options.path.startsWith('https://nominatim.openstreetmap.org')) {
      options.headers['Authorization'] = 'Bearer ${StorageRepository.getString(StoreKeys.token)}';
    }
    return handler.next(options);
  }
}

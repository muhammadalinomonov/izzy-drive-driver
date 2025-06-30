import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:taxi_app/src/core/network/injection.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/routes/app_router.dart';
import 'package:taxi_app/src/routes/pages.dart';

@module
abstract class DioModule {
  @lazySingleton
  Dio dio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://catering.mukhsin.space/api/v1',
        headers: {'Content-Type': 'application/json', 'Accept-Language': 'en'},
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    // ?  https://catering.mukhsin.space/api/v1employee/hiring-expense/33a341cf-429a-4fb3-9245-a837cdc9ff5f/
    // * https://catering.mukhsin.space/api/v1/employee/hiring-expense/42caec56-40ca-4be3-82ed-b78badb81671/

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['Accept'] = 'application/json';
          String? token = sl<TokenService>().accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            if (error.response?.data['messages'] == null) {
              sl<TokenService>().clear();
              Routes.router.go(Pages.signIn);
              return handler.reject(error);
            }
            // final result = await sl<AuthRepo>().refreshTokens();
            // if (result.isRight()) {
              String? token = sl<TokenService>().accessToken;
              dio.options.headers['Authorization'] = 'Bearer $token';
              return handler.resolve(await dio.fetch(error.requestOptions));
            // }
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  }
}

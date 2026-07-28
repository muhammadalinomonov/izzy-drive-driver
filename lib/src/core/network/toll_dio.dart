import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:taxi_app/src/core/network/toll_api_constants.dart';
import 'package:taxi_app/src/core/network/toll_session.dart';

/// Dio client for the Quadrix Tolling backend.
///
/// Deliberately separate from [DioSettings]: that instance is pinned to
/// `api.izzydrive.com` and carries a SimpleJWT refresh interceptor that would
/// try to refresh a Quadrix Sanctum token against the wrong host on a 401.
/// Sanctum tokens don't refresh — they're re-issued by logging in again — so
/// this client surfaces auth failures to the caller instead of retrying.
class TollDioSettings {
  static final TollDioSettings _instance = TollDioSettings._internal();
  factory TollDioSettings() => _instance;

  late final Dio dio;

  TollDioSettings._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: TollApiConstants.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    dio.interceptors
      ..add(
        InterceptorsWrapper(
          // Every request through this client - toll routes today, bootstrap /
          // vehicles / navigation tomorrow - gets both credentials here, so no
          // data source has to know about auth.
          onRequest: (options, handler) async {
            final token = TollSession.token;
            if (token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            // Resolved from auth/me on first use and cached; see TollSession.
            final orgId = await TollSession.ensureOrganizationId();
            if (orgId.isNotEmpty) {
              options.headers[TollApiConstants.organizationHeader] = orgId;
            }
            handler.next(options);
          },
        ),
      )
      ..add(
        PrettyDioLogger(
          requestBody: true,
          responseBody: true,
          error: true,
          request: true,
          requestHeader: true,
          responseHeader: false,
        ),
      )
      ..add(ChuckerDioInterceptor());
  }
}

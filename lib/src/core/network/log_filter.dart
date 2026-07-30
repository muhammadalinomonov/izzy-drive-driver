import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:dio/dio.dart';

/// Paths whose request/response logging is suppressed everywhere — both the
/// console (`PrettyDioLogger`) and the in-app Chucker inspector. These are
/// polled endpoints: logging them adds no signal and drowns out everything
/// else, and in Chucker's case it pushes real requests out of the capped
/// history within seconds.
const List<String> kLogMutedPaths = ['drivers/current-order/'];

bool isLogMuted(String path) =>
    kLogMutedPaths.any((muted) => path.contains(muted));

/// [ChuckerDioInterceptor] with no filter hook of its own, so muted paths are
/// dropped before the base class can save them or fire its notification.
class FilteredChuckerDioInterceptor extends ChuckerDioInterceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Bypassing super also keeps the poller from clobbering the base class's
    // single `_requestTime` field, which a concurrent real request needs.
    if (isLogMuted(options.path)) {
      handler.next(options);
      return;
    }
    await super.onRequest(options, handler);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    if (isLogMuted(response.requestOptions.path)) {
      handler.next(response);
      return;
    }
    await super.onResponse(response, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (isLogMuted(err.requestOptions.path)) {
      handler.next(err);
      return;
    }
    await super.onError(err, handler);
  }
}

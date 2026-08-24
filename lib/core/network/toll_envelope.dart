import 'package:taxi_app/core/utils/json_safe.dart';

/// Shared error-envelope parsing for every Quadrix Tolling data source.
///
/// All of them (`route_support_data_source.dart`, `support_chat_data_source.dart`,
/// `fuel_stations_data_source.dart`, `trips_data_source.dart`, ...) hit the
/// same backend and get back the same `{ "error": { "code", "message" } }`
/// shape on failure - this used to be copy-pasted as a private static pair in
/// each file. One copy here, one behavior everywhere.

/// Human-readable message out of a toll-API error body.
String tollErrorMessage(dynamic body, [String fallback = 'Server error']) {
  if (body is Map) {
    final error = body['error'];
    if (error is Map) {
      final message = error['message'];
      if (message is String && message.isNotEmpty) return message;
    }
  }
  return dioErrorMessage(body, fallback);
}

/// Machine-readable `error.code` (e.g. `VALIDATION_FAILED`), or null when the
/// body carries none.
String? tollErrorCode(dynamic body) {
  if (body is! Map) return null;
  final error = body['error'];
  if (error is! Map) return null;
  final code = error['code'];
  return code is String && code.isNotEmpty ? code : null;
}

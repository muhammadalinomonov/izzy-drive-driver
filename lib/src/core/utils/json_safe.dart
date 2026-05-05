/// Safe JSON value parsers — never throw, always return a sensible default.
///
/// Backend may return null, omit a field, or send a numeric value as a string
/// (or vice-versa). Use these helpers in `fromJson` factories instead of raw
/// `as int` / `as String` casts to avoid runtime crashes.
library;

double toDouble(dynamic value, [double fallback = 0.0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int toInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

String toStr(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

String? toStrNullable(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : value;
  return value.toString();
}

bool toBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.toLowerCase();
    if (v == 'true' || v == '1') return true;
    if (v == 'false' || v == '0') return false;
  }
  return fallback;
}

Map<String, dynamic> toMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<T> toList<T>(dynamic value, T Function(dynamic) mapper) {
  if (value is! List) return <T>[];
  final result = <T>[];
  for (final e in value) {
    try {
      result.add(mapper(e));
    } catch (_) {}
  }
  return result;
}

/// Pull a human-readable error message out of a Dio response body.
///
/// Backend may return:
/// - `{ "message": "..." }`
/// - `{ "detail": "..." }`
/// - a plain string
/// - HTML (e.g. nginx 502)
/// - null / no body at all
///
/// Always returns a non-empty string.
String dioErrorMessage(dynamic responseData, [String fallback = 'Server error']) {
  if (responseData == null) return fallback;
  if (responseData is String) {
    return responseData.isEmpty ? fallback : responseData;
  }
  if (responseData is Map) {
    final msg = responseData['message'] ?? responseData['detail'] ?? responseData['error'];
    if (msg is String && msg.isNotEmpty) return msg;
    if (msg is Map) {
      final nested = msg['detail'] ?? msg['message'];
      if (nested is String && nested.isNotEmpty) return nested;
    }
    if (msg != null) return msg.toString();
  }
  return fallback;
}
class NetworkResponse<T> {
  final String errorText;
  // Server-defined error code (e.g., "otp_expired", "otp_too_many_attempts").
  // Optional — most endpoints don't use it. Use to branch on specific errors.
  final String? errorCode;
  final T? data;

  NetworkResponse({
    this.errorText = "",
    this.errorCode,
    this.data,
  });
}
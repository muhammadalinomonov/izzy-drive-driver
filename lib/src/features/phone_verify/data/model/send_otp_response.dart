class SendOtpResponse {
  final int expiresIn;
  final int resendAfter;

  const SendOtpResponse({
    required this.expiresIn,
    required this.resendAfter,
  });

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) => SendOtpResponse(
        expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
        resendAfter: (json['resend_after'] as num?)?.toInt() ?? 0,
      );
}

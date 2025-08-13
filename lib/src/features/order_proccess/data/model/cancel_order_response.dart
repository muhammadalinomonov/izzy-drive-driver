class CancelOrderResponse {
  final bool status;
  final String message;
  final List<dynamic> data;

  CancelOrderResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory CancelOrderResponse.fromJson(Map<String, dynamic> json) {
    return CancelOrderResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data,
    };
  }
}

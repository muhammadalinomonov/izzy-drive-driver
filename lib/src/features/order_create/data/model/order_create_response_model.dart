/// Backend response from `POST /drivers/create-report/`.
/// Manually parsed (no `@JsonSerializable`) because the project's
/// `build_runner` is currently broken on `retrofit_generator`.
class OrderCreateResponseModel {
  const OrderCreateResponseModel({this.status, this.message, this.data});

  final bool? status;
  final String? message;
  final OrderCreateData? data;

  factory OrderCreateResponseModel.fromJson(Map<String, dynamic> json) {
    return OrderCreateResponseModel(
      status: json['status'] as bool?,
      message: json['message'] as String?,
      data: json['data'] is Map<String, dynamic>
          ? OrderCreateData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class OrderCreateData {
  const OrderCreateData({this.orderId, this.orderStatus});

  final int? orderId;
  final String? orderStatus;

  factory OrderCreateData.fromJson(Map<String, dynamic> json) {
    return OrderCreateData(
      orderId: (json['order_id'] as num?)?.toInt(),
      orderStatus: json['order_status'] as String?,
    );
  }
}

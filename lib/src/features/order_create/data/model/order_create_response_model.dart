import 'package:taxi_app/src/core/utils/json_safe.dart';

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
      status: json['status'] == null ? null : toBool(json['status']),
      message: toStrNullable(json['message']),
      data: json['data'] is Map
          ? OrderCreateData.fromJson(toMap(json['data']))
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
      orderId: json['order_id'] == null ? null : toInt(json['order_id']),
      orderStatus: toStrNullable(json['order_status']),
    );
  }
}

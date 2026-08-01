// File: lib/src/features/chat/data/model/report_response_model.dart
import 'package:taxi_app/core/utils/json_safe.dart';

class ReportResponse {
  final bool status;
  final String message;
  final ReportData data;

  ReportResponse({required this.status, required this.message, required this.data});

  factory ReportResponse.fromJson(Map<String, dynamic> json) {
    return ReportResponse(
      status: toBool(json['status']),
      message: toStr(json['message']),
      data: ReportData.fromJson(toMap(json['data'])),
    );
  }
}

class ReportData {
  final Report report;
  final int orderId;
  final String orderStatus;

  ReportData({required this.report, required this.orderId, required this.orderStatus});

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      report: Report.fromJson(toMap(json['report'])),
      orderId: toInt(json['order_id']),
      orderStatus: toStr(json['order_status']),
    );
  }
}

class Report {
  final int id;
  final int sender;
  final String text;
  final dynamic voiceFile; // null or File path
  final List<dynamic> images; // Empty list or File paths
  final String price;
  final DateTime createdAt;
  final Address address;

  Report({
    required this.id,
    required this.sender,
    required this.text,
    required this.voiceFile,
    required this.images,
    required this.price,
    required this.createdAt,
    required this.address,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: toInt(json['id']),
      sender: toInt(json['sender']),
      text: toStr(json['text']),
      voiceFile: json['voice_file'],
      images: json['images'] is List ? List<dynamic>.from(json['images']) : <dynamic>[],
      price: toStr(json['price']),
      createdAt: DateTime.tryParse(toStr(json['created_at'])) ?? DateTime.now(),
      address: Address.fromJson(toMap(json['address'])),
    );
  }
}

class Address {
  final double latitude;
  final double longitude;
  final String address;
  final bool isStatic;

  const Address({this.latitude = 0, this.longitude = 0, this.address = '', this.isStatic = false});

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
      address: toStr(json['address']),
      isStatic: toBool(json['is_static']),
    );
  }
}
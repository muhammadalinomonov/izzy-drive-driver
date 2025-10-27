// File: lib/src/features/chat/data/model/report_response_model.dart
import 'dart:io';

class ReportResponse {
  final bool status;
  final String message;
  final ReportData data;

  ReportResponse({required this.status, required this.message, required this.data});

  factory ReportResponse.fromJson(Map<String, dynamic> json) {
    try {
      return ReportResponse(
        status: json['status'] as bool,
        message: json['message'] as String,
        data: ReportData.fromJson(json['data'] as Map<String, dynamic>),
      );
    } catch (e) {
      print('Error parsing ReportResponse: $e');
      rethrow; // Xatni qayta chiqarish
    }
  }
}

class ReportData {
  final Report report;
  final int orderId;
  final String orderStatus;

  ReportData({required this.report, required this.orderId, required this.orderStatus});

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      report: Report.fromJson(json['report']),
      orderId: json['order_id'],
      orderStatus: json['order_status'],
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
      id: json['id'] ?? 0,
      sender: json['sender'],
      text: json['text'],
      voiceFile: json['voice_file'],
      images: json['images'],
      price: json['price'],
      createdAt: DateTime.parse(json['created_at']),
      address: Address.fromJson(json['address']),
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
      latitude: json['latitude'] ?? 0,
      longitude: json['longitude'] ?? 0,
      address: json['address'] ?? '',
      isStatic: json['is_static'] ?? false,
    );
  }
}

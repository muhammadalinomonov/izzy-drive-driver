import 'package:taxi_app/src/core/utils/json_safe.dart';

class OrderResponse {
  final bool status;
  final String message;
  final int total;
  final int totalPages;
  final int currentPage;
  final dynamic next;
  final dynamic previous;
  final List<OrderData> data;
  final Order order;

  OrderResponse({
    required this.status,
    required this.message,
    required this.total,
    required this.totalPages,
    required this.currentPage,
    this.next,
    this.previous,
    required this.data,
    required this.order,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      status: toBool(json['status']),
      message: toStr(json['message'], ' '),
      total: toInt(json['total']),
      totalPages: toInt(json['total_pages']),
      currentPage: toInt(json['current_page']),
      next: json['next'],
      previous: json['previous'],
      data: toList(json['data'], (e) => OrderData.fromJson(toMap(e))),
      order: Order.fromJson(toMap(json['order'])),
    );
  }

  OrderResponse copyWith({
    bool? status,
    String? message,
    int? total,
    int? totalPages,
    int? currentPage,
    dynamic? next,
    dynamic? previous,
    List<OrderData>? data,
    Order? order,
  }) {
    return OrderResponse(
      status: status ?? this.status,
      message: message ?? this.message,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      next: next ?? this.next,
      previous: previous ?? this.previous,
      data: data ?? this.data,
      order: order ?? this.order,
    );
  }
}

class OrderData {
  final int id;
  final int mechanicId;
  final String mechanicName;
  final String shopAddress;
  final double distance;
  final String? avatar;
  final String mechanicCurrentAddress; // API'dan kelgan raw string
  final double proposedPrice;
  final String createdAt;
  final String balance;
  final double changePercent;
  final int? workTimeEstimateMin;

  OrderData({
    required this.id,
    required this.mechanicId,
    required this.mechanicName,
    required this.shopAddress,
    required this.distance,
    this.avatar,
    required this.mechanicCurrentAddress,
    required this.proposedPrice,
    required this.createdAt,
    required this.balance,
    required this.changePercent,
    this.workTimeEstimateMin,
  });

  factory OrderData.fromJson(Map<String, dynamic> json) {
    return OrderData(
      id: toInt(json['id']),
      mechanicId: toInt(json['mechanic_id']),
      mechanicName: toStr(json['mechanic_name']),
      shopAddress: toStr(json['shop_address']),
      distance: toDouble(json['distance']),
      avatar: toStrNullable(json['avatar']),
      mechanicCurrentAddress: toStr(json['mechanic_current_address']),
      proposedPrice: toDouble(json['proposed_price']),
      createdAt: toStr(json['created_at']),
      balance: toStr(json['balance']),
      changePercent: toDouble(json['change_percent']),
      workTimeEstimateMin: (json['work_time_estimate_min'] as num?)?.toInt(),
    );
  }
}

class Order {
  final int id;
  final String orderTitle;
  final double price;
  final String status;
  final CurrentAddress currentAddress;
  final String createdAt;
  final double totalPrice;

  Order({
    required this.id,
    required this.orderTitle,
    required this.price,
    required this.status,
    required this.currentAddress,
    required this.createdAt,
    required this.totalPrice,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: toInt(json['id'], -1),
      orderTitle: toStr(json['order_title']),
      price: toDouble(json['price']),
      status: toStr(json['status']),
      currentAddress: CurrentAddress.fromJson(toMap(json['current_address'])),
      createdAt: toStr(json['created_at']),
      totalPrice: toDouble(json['total_price']),
    );
  }

  Order copyWith({double? price, String? status, CurrentAddress? currentAddress, double? totalPrice}) {
    return Order(
      id: id,
      createdAt: createdAt,
      currentAddress: currentAddress ?? this.currentAddress,
      orderTitle: orderTitle,
      price: price ?? this.price,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}

class CurrentAddress {
  final double latitude;
  final double longitude;
  final String address;
  final bool isStatic;

  CurrentAddress({required this.latitude, required this.longitude, required this.address, required this.isStatic});

  factory CurrentAddress.fromJson(Map<String, dynamic> json) {
    return CurrentAddress(
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
      address: toStr(json['address']),
      isStatic: toBool(json['is_static']),
    );
  }
}

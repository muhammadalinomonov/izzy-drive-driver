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
      status: json['status'] as bool,
      message: json['message'] as String,
      total: json['total'] as int,
      totalPages: json['total_pages'] as int,
      currentPage: json['current_page'] as int,
      next: json['next'],
      previous: json['previous'],
      data: (json['data'] as List<dynamic>)
          .map((e) => OrderData.fromJson(e as Map<String, dynamic>))
          .toList(),
      order: Order.fromJson(json['order'] as Map<String, dynamic>),
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
  });

  factory OrderData.fromJson(Map<String, dynamic> json) {
    return OrderData(
      id: json['id'] as int,
      mechanicId: json['mechanic_id'] as int,
      mechanicName: json['mechanic_name'] as String,
      shopAddress: json['shop_address'] as String,
      distance: _toDouble(json['distance']),
      avatar: json['avatar'] as String?,
      mechanicCurrentAddress: json['mechanic_current_address'] as String,
      proposedPrice: _toDouble(json['proposed_price']),
      createdAt: json['created_at'] as String,
      balance: json['balance'] as String,
      changePercent: _toDouble(json['change_percent']),
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
      id: json['id'] as int,
      orderTitle: json['order_title'] as String,
      price: _toDouble(json['price']),
      status: json['status'] as String,
      currentAddress: CurrentAddress.fromJson(json['current_address']),
      createdAt: json['created_at'] as String,
      totalPrice: _toDouble(json['total_price']),
    );
  }
}

class CurrentAddress {
  final double latitude;
  final double longitude;
  final String address;
  final bool isStatic;

  CurrentAddress({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.isStatic,
  });

  factory CurrentAddress.fromJson(Map<String, dynamic> json) {
    return CurrentAddress(
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      address: json['address'] as String,
      isStatic: json['is_static'] as bool,
    );
  }
}

/// Helper function to safely parse double from dynamic
double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

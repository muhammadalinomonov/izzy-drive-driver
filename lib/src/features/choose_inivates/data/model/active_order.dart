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

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'total': total,
      'total_pages': totalPages,
      'current_page': currentPage,
      'next': next,
      'previous': previous,
      'data': data.map((e) => e.toJson()).toList(),
      'order': order.toJson(),
    };
  }
}

class OrderData {
  final int id;
  final int mechanicId;
  final String mechanicName;
  final String shopAddress;
  final String distance;
  final String? avatar;
  final String mechanicCurrentAddress;
  final String proposedPrice;
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
      distance: json['distance'] as String,
      avatar: json['avatar'] as String?,
      mechanicCurrentAddress: json['mechanic_current_address'] as String,
      proposedPrice: json['proposed_price'] as String,
      createdAt: json['created_at'] as String,
      balance: json['balance'] as String,
      changePercent: (json['change_percent'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mechanic_id': mechanicId,
      'mechanic_name': mechanicName,
      'shop_address': shopAddress,
      'distance': distance,
      'avatar': avatar,
      'mechanic_current_address': mechanicCurrentAddress,
      'proposed_price': proposedPrice,
      'created_at': createdAt,
      'balance': balance,
      'change_percent': changePercent,
    };
  }
}

class Order {
  final int id;
  final String orderTitle;
  final String price;
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
      price: json['price'] as String,
      status: json['status'] as String,
      currentAddress: CurrentAddress.fromJson(json['current_address'] as Map<String, dynamic>),
      createdAt: json['created_at'] as String,
      totalPrice: (json['total_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_title': orderTitle,
      'price': price,
      'status': status,
      'current_address': currentAddress.toJson(),
      'created_at': createdAt,
      'total_price': totalPrice,
    };
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
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
      isStatic: json['is_static'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'is_static': isStatic,
    };
  }
}
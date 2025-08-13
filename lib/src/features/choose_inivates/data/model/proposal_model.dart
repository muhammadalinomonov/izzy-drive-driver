// File: proposal_model.dart
import 'dart:convert';

class Proposal {
  final OrderInfo orderInfo;
  final MechanicInfo mechanicInfo;
  final List<Review> reviews;

  Proposal({
    required this.orderInfo,
    required this.mechanicInfo,
    required this.reviews,
  });

  factory Proposal.fromJson(Map<String, dynamic> json) {
    return Proposal(
      orderInfo: OrderInfo.fromJson(json['order_info'] ?? {}),
      mechanicInfo: MechanicInfo.fromJson(json['mechanic_info'] ?? {}),
      reviews: (json['reviews'] as List<dynamic>?)?.map((r) => Review.fromJson(r as Map<String, dynamic>)).toList() ?? [],
    );
  }
}

class OrderInfo {
  final String orderTitle;
  final String orderAddress;
  final double orderPrice;
  final double distance;
  final double proposalPrice;
  final String createdAt;

  OrderInfo({
    required this.orderTitle,
    required this.orderAddress,
    required this.orderPrice,
    required this.distance,
    required this.proposalPrice,
    required this.createdAt,
  });

  factory OrderInfo.fromJson(Map<String, dynamic> json) {
    return OrderInfo(
      orderTitle: json['order_title'] as String? ?? '',
      orderAddress: json['order_address'] as String? ?? '',
      orderPrice: (json['order_price'] as num?)?.toDouble() ?? 0.0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      proposalPrice: (json['proposal_price'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class MechanicInfo {
  final int mechanicId;
  final String mechanicName;
  final String shopAddress;
  final String avatar;
  final CurrentAddress currentAddress;
  final int allOrdersCount;
  final int successOrdersCount;
  final Performance performance;

  MechanicInfo({
    required this.mechanicId,
    required this.mechanicName,
    required this.shopAddress,
    required this.avatar,
    required this.currentAddress,
    required this.allOrdersCount,
    required this.successOrdersCount,
    required this.performance,
  });

  factory MechanicInfo.fromJson(Map<String, dynamic> json) {
    return MechanicInfo(
      mechanicId: json['mechanic_id'] as int? ?? 0,
      mechanicName: json['mechanic_name'] as String? ?? '',
      shopAddress: json['shop_address'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      currentAddress: CurrentAddress.fromJson(json['current_address'] ?? {}),
      allOrdersCount: json['all_orders_count'] as int? ?? 0,
      successOrdersCount: json['success_orders_count'] as int? ?? 0,
      performance: Performance.fromJson(json['performance'] ?? {}),
    );
  }
}

class CurrentAddress {
  final double latitude;
  final double longitude;

  CurrentAddress({required this.latitude, required this.longitude});

  factory CurrentAddress.fromJson(Map<String, dynamic> json) {
    return CurrentAddress(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitute'] as num?)?.toDouble() ?? 0.0, // Handle typo
    );
  }
}

class Performance {
  final double averageStars;
  final int totalReviews;

  Performance({required this.averageStars, required this.totalReviews});

  factory Performance.fromJson(Map<String, dynamic> json) {
    return Performance(
      averageStars: (json['average_stars'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
    );
  }
}

class Review {
  final int id;
  final int driver;
  final String driverName;
  final String? driverAvatar;
  final int stars;
  final String comment;
  final String createdAt;

  Review({
    required this.id,
    required this.driver,
    required this.driverName,
    this.driverAvatar,
    required this.stars,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int? ?? 0,
      driver: json['driver'] as int? ?? 0,
      driverName: json['driver_name'] as String? ?? '',
      driverAvatar: json['driver_avatar'] as String?,
      stars: json['stars'] as int? ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
// File: proposal_model.dart
import 'package:taxi_app/src/core/utils/json_safe.dart';

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
      orderInfo: OrderInfo.fromJson(toMap(json['order_info'])),
      mechanicInfo: MechanicInfo.fromJson(toMap(json['mechanic_info'])),
      reviews: toList(json['reviews'], (r) => Review.fromJson(toMap(r))),
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
      orderTitle: toStr(json['order_title']),
      orderAddress: toStr(json['order_address']),
      orderPrice: toDouble(json['order_price']),
      distance: toDouble(json['distance']),
      proposalPrice: toDouble(json['proposal_price']),
      createdAt: toStr(json['created_at']),
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
      mechanicId: toInt(json['mechanic_id']),
      mechanicName: toStr(json['mechanic_name']),
      shopAddress: toStr(json['shop_address']),
      avatar: toStr(json['avatar']),
      currentAddress: CurrentAddress.fromJson(toMap(json['current_address'])),
      allOrdersCount: toInt(json['all_orders_count']),
      successOrdersCount: toInt(json['success_orders_count']),
      performance: Performance.fromJson(toMap(json['performance'])),
    );
  }
}

class CurrentAddress {
  final double latitude;
  final double longitude;

  CurrentAddress({required this.latitude, required this.longitude});

  factory CurrentAddress.fromJson(Map<String, dynamic> json) {
    return CurrentAddress(
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitute']), // Handle typo
    );
  }
}

class Performance {
  final double averageStars;
  final int totalReviews;

  Performance({required this.averageStars, required this.totalReviews});

  factory Performance.fromJson(Map<String, dynamic> json) {
    return Performance(
      averageStars: toDouble(json['average_stars']),
      totalReviews: toInt(json['total_reviews']),
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
      id: toInt(json['id']),
      driver: toInt(json['driver']),
      driverName: toStr(json['driver_name']),
      driverAvatar: toStrNullable(json['driver_avatar']),
      stars: toInt(json['stars']),
      comment: toStr(json['comment']),
      createdAt: toStr(json['created_at']),
    );
  }
}
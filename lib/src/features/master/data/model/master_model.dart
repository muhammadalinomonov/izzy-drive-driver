import 'package:taxi_app/src/features/master/data/model/review_model.dart';

class MasterModel {
  final int? id;
  final String? fullName;
  final String? photo;
  final double? rating;
  final String? status;
  final int? experience;
  final String? distanceKm;
  final String createdAt;
  final int allOrdersCount;
  final int successOrdersCount;
  final int reviewCount;
  final ReviewModel? review;
  final String allReviewsUrl;
  final double distance;

  const MasterModel({
    this.id,
    this.fullName,
    this.photo,
    this.rating,
    this.status,
    this.experience,
    this.distanceKm,
    this.createdAt = '',
    this.allOrdersCount = 0,
    this.successOrdersCount = 0,
    this.reviewCount = 0,
    this.review,
    this.allReviewsUrl = '',
    this.distance = 0,
  });

  factory MasterModel.fromJson(Map<String, dynamic> json) {
    return MasterModel(
      id: json['id'] as int? ?? 0,
      fullName: json['full_name'] as String? ?? '',
      photo: json['photo'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
      experience: json['experience'] as int? ?? 0,
      distanceKm: json['distance_km']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      allOrdersCount: json['all_orders_count'] as int? ?? 0,
      successOrdersCount: json['success_orders_count'] as int? ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
      review: json['review'] != null ? ReviewModel.fromJson(json['review'] as Map<String, dynamic>) : null,
      allReviewsUrl: json['all_reviews_url']?.toString() ?? '',
      distance: (json['distance'] as num?)?.toDouble() ?? 0,
    );
  }
}

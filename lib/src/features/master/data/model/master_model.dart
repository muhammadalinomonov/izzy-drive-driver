import 'package:taxi_app/src/core/utils/json_safe.dart';
import 'package:taxi_app/src/features/master/data/model/review_model.dart';
import 'package:taxi_app/src/features/profile/domain/entities/map_entity.dart';

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
  final double latitude;
  final double longitude;
  final MapEntity map;

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
    this.latitude = 0,
    this.longitude = 0,
    this.map = const MapEntity(),
  });

  factory MasterModel.fromJson(Map<String, dynamic> json) {
    return MasterModel(
      id: toInt(json['id']),
      fullName: toStr(json['full_name']),
      photo: toStr(json['photo']),
      rating: toDouble(json['rating']),
      status: toStr(json['status']),
      experience: toInt(json['experience']),
      distanceKm: toStr(json['distance_km']),
      createdAt: toStr(json['created_at']),
      allOrdersCount: toInt(json['all_orders_count']),
      successOrdersCount: toInt(json['success_orders_count']),
      reviewCount: toInt(json['review_count']),
      review: json['review'] != null ? ReviewModel.fromJson(toMap(json['review'])) : null,
      allReviewsUrl: toStr(json['all_reviews_url']),
      distance: toDouble(json['distance']),
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
      map: json['map'] != null ? MapEntity.fromJson(toMap(json['map'])) : const MapEntity(),
    );
  }
}

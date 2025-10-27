import 'package:equatable/equatable.dart';

class ReviewModel extends Equatable {
  final int id;
  final int driver;
  final String driverName;
  final String driverAvatar;
  final int stars;
  final String comment;
  final String createdAt;

  const ReviewModel({
    this.id = -1,
    this.driver = -1,
    this.driverName = '',
    this.driverAvatar = '',
    this.stars = 0,
    this.comment = '',
    this.createdAt = '',
  });

  @override
  List<Object> get props => [id, driver, driverName, driverAvatar, stars, comment, createdAt];

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? -1,
      driver: json['driver'] ?? -1,
      driverName: json['driver_name'] ?? '',
      comment: json['comment'] ?? '',
      driverAvatar: json['driver_avatar'] ?? '',
      stars: json['stars'] ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }
}

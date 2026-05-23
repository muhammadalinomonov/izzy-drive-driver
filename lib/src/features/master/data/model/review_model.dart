import 'package:equatable/equatable.dart';
import 'package:taxi_app/src/core/utils/json_safe.dart';

class ReviewModel extends Equatable {
  final int id;
  final int driver;
  final String driverName;
  final String driverAvatar;
  final int stars;
  final String comment;
  // Optional short tag chosen by the driver (e.g. "On time", "Polite").
  // Backend column is CharField(blank=True, null=True) so empty is normal.
  final String tag;
  final String createdAt;

  const ReviewModel({
    this.id = -1,
    this.driver = -1,
    this.driverName = '',
    this.driverAvatar = '',
    this.stars = 0,
    this.comment = '',
    this.tag = '',
    this.createdAt = '',
  });

  @override
  List<Object> get props => [id, driver, driverName, driverAvatar, stars, comment, tag, createdAt];

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: toInt(json['id'], -1),
      driver: toInt(json['driver'], -1),
      driverName: toStr(json['driver_name']),
      comment: toStr(json['comment']),
      tag: toStr(json['tag']),
      driverAvatar: toStr(json['driver_avatar']),
      stars: toInt(json['stars']),
      createdAt: toStr(json['created_at']),
    );
  }
}

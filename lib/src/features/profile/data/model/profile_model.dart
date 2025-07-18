import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  ProfileModel({
    required super.name,
    required super.email,
    required super.initials,
    required super.vehicle,
    required super.balance,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      initials: json['initials'] ?? '',
      vehicle: json['vehicle'] ?? '',
      balance: json['balance'] ?? '',
    );
  }
}

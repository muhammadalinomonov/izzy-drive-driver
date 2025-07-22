class MasterModel {
  final int? id;
  final String? fullName;
  final String? photo;
  final double? rating;
  final String? status;
  final int? experience;
  final String? distanceKm;

  MasterModel({
    this.id,
    this.fullName,
    this.photo,
    this.rating,
    this.status,
    this.experience,
    this.distanceKm,
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
    );
  }
}

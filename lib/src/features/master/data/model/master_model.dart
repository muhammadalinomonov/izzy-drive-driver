class MasterModel {
  final int id;
  final String name;
  final double rating;
  final int experience;
  final String avatarUrl;

  MasterModel({
    required this.id,
    required this.name,
    required this.rating,
    required this.experience,
    required this.avatarUrl,
  });

  factory MasterModel.fromJson(Map<String, dynamic> json) {
    return MasterModel(
      id: json['id'] as int,
      name: json['name'] as String,
      rating: (json['rating'] as num).toDouble(),
      experience: json['experience'] as int,
      avatarUrl: json['avatar_url'] as String? ?? '',
    );
  }
}

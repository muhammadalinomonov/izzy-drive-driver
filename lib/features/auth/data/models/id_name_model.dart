import 'package:mechanic/features/auth/domain/entities/id_name_entity.dart';

class IdNameModel extends IdNameEntity {
  const IdNameModel({
    super.id,
    super.name,
  });

  factory IdNameModel.fromJson(Map<String, dynamic> json) {
    return IdNameModel(
      id: json['int'] is int ? json['int'] : -1,
      name: json['string'] ?? '',
    );
  }
}

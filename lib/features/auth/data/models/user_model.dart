import 'package:json_annotation/json_annotation.dart';
import 'package:mechanic/features/auth/domain/entities/id_name_entity.dart';
import 'package:mechanic/features/auth/domain/entities/user_entity.dart';

part 'user_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserModel extends UserEntity {
  const UserModel({
    super.id,
    super.phoneNumber,
    super.fullName,
    super.status,
    super.photo,
    super.balance,
    super.deviceToken,
    super.wsId,
    super.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}

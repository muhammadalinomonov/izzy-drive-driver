import 'package:json_annotation/json_annotation.dart';
import 'package:mechanic/features/main/domain/entities/address_entity.dart';

part 'current_address_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CurrentAddressModel extends CurrentAddressEntity {
  const CurrentAddressModel({
    super.latitude,
    super.longitude,
    super.address,
    super.isStatic,
  });

  factory CurrentAddressModel.fromJson(Map<String, dynamic> json) {
    return _$CurrentAddressModelFromJson(json);
  }
}

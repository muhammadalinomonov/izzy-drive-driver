import 'package:json_annotation/json_annotation.dart';
import 'package:mechanic/features/main/domain/entities/image_entity.dart';

part 'image_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ImageModel extends ImageEntity{
  const  ImageModel({
    super.id,
    super.image,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) => _$ImageModelFromJson(json);
  Map<String, dynamic> toJson() => _$ImageModelToJson(this);
}
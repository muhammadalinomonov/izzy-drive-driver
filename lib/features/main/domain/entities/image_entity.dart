import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mechanic/features/main/data/models/image_model.dart';

class ImageEntity extends Equatable {
  final int id;
  final String image;

  const ImageEntity({
    this.id = -1,
    this.image = '',
  });

  @override
  List<Object?> get props => [id, image];
}
class ImageEntityConverter implements JsonConverter<ImageEntity, Map<String, dynamic>> {
  const ImageEntityConverter();

  @override
  ImageEntity fromJson(Map<String, dynamic> json) {
    return ImageModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(ImageEntity entity) {
    return {
      'id': entity.id,
      'image': entity.image,
    };
  }
}
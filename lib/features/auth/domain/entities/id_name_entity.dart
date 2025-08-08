import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mechanic/features/auth/data/models/id_name_model.dart';

class IdNameEntity extends Equatable{
  final int id;
  final dynamic name;

  const IdNameEntity({
    this.id = -1,
    this.name = '',
  });

  @override
  List<Object?> get props => [id, name];
}

class IdNameEntityConvertor implements JsonConverter<IdNameEntity, Map<String, dynamic>> {
  const IdNameEntityConvertor();

  @override
  IdNameEntity fromJson(Map<String, dynamic> json) => IdNameModel.fromJson(json);

  @override
  Map<String, dynamic> toJson(IdNameEntity instance) => <String, dynamic>{
    'id': instance.id,
    'string': instance.name,
  };
}
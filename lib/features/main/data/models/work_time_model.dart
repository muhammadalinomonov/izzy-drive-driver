import 'package:json_annotation/json_annotation.dart';
import 'package:mechanic/features/main/domain/entities/work_time_entity.dart';

part 'work_time_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class WorkTimeModel extends WorkTimeEntity {
  const WorkTimeModel({
    super.days,
    super.hours,
    super.minutes,
  });

  factory WorkTimeModel.fromJson(Map<String, dynamic> json) =>
      _$WorkTimeModelFromJson(json);

  Map<String, dynamic> toJson() => _$WorkTimeModelToJson(this);
}

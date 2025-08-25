import 'package:json_annotation/json_annotation.dart';
import 'package:mechanic/features/profile/domain/entities/static_entity.dart';

part 'statistic_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class StatisticModel extends StatisticEntity {
  const StatisticModel({
    super.date,
    super.dateStr,
    super.ordersCount,
    super.totalSum,
    super.percentage,
    super.selected,
  });

  factory StatisticModel.fromJson(Map<String, dynamic> json) => _$StatisticModelFromJson(json);

  Map<String, dynamic> toJson() => _$StatisticModelToJson(this);
}

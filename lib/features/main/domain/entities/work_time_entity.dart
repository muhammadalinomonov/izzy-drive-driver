import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mechanic/features/main/data/models/work_time_model.dart';

class WorkTimeEntity extends Equatable {
  final int days;
  final int hours;
  final int minutes;

  const WorkTimeEntity({
    this.days = 0,
    this.hours = 0,
    this.minutes = 0,
  });

  @override
  List<Object?> get props => [days, hours, minutes];

  String get formattedTime {
    final String dayStr = days > 0 ? '$days day${days > 1 ? 's' : ''} ' : '';
    final String hourStr = hours > 0 ? '$hours hour${hours > 1 ? 's' : ''} ' : '';
    final String minuteStr = minutes > 0 ? '$minutes minute${minutes > 1 ? 's' : ''}' : '';

    return '$dayStr$hourStr$minuteStr'.trim();
  }
}

class WorkTimeEntityConverter implements JsonConverter<WorkTimeEntity, Map<String, dynamic>> {
  const WorkTimeEntityConverter();

  @override
  WorkTimeEntity fromJson(Map<String, dynamic> json) {
    return WorkTimeModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(WorkTimeEntity object) {
    return {
      'days': object.days,
      'hours': object.hours,
      'minutes': object.minutes,
    };
  }
}
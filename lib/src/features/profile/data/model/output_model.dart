import 'package:taxi_app/src/core/utils/json_safe.dart';
import 'package:taxi_app/src/features/profile/domain/entities/output_entity.dart';

class OutPutModel extends OutPutEntity {
  const OutPutModel({super.id, super.driver, super.title, super.amount, super.date, super.createdAt});

  factory OutPutModel.fromJson(Map<String, dynamic> json) {
    return OutPutModel(
      id: toInt(json['id'], -1),
      driver: toInt(json['driver'], -1),
      title: toStr(json['title']),
      amount: toStr(json['amount']),
      date: toStr(json['date']),
      createdAt: toStr(json['created_at']),
    );
  }
}

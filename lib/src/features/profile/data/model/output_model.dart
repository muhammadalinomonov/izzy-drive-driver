import 'package:taxi_app/src/features/profile/domain/entities/output_entity.dart';

class OutPutModel extends OutPutEntity {
  const OutPutModel({super.id, super.driver, super.title, super.amount, super.date, super.createdAt});

  factory OutPutModel.fromJson(Map<String, dynamic> json) {
    return OutPutModel(
      id: json['id'] ?? -1,
      driver: json['driver'] ?? -1,
      title: json['title'] ?? '',
      amount: json['amount'] ?? '',
      date: json['date'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

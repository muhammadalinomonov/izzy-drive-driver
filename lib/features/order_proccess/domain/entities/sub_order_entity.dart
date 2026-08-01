import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:taxi_app/features/order_proccess/data/model/sub_order_model.dart';

class SubOrderEntity extends Equatable {
  final int id;
  final String title;
  final String price;
  final String status;
  final String createdAt;

  const SubOrderEntity({this.id = -1, this.title = '', this.status = '', this.createdAt = '', this.price = ''});

  @override
  List<Object?> get props => [id, title, status, createdAt, price];
}

class SubOrderEntityConverter implements JsonConverter<SubOrderEntity, Map<String, dynamic>> {
  @override
  SubOrderEntity fromJson(Map<String, dynamic> json) {
    return SubOrderModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(SubOrderEntity object) {
    return {};
  }
}

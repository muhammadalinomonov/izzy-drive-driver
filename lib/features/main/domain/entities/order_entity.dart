import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mechanic/features/main/data/models/order_model.dart';
import 'package:mechanic/features/main/domain/entities/image_entity.dart';
import 'package:mechanic/features/main/domain/entities/proposal_entity.dart';

class OrderEntity extends Equatable {
  final int id;
  final String orderTitle;
  final String price;
  final String status;
  final dynamic selectedMechanic;
  @ProposalEntityConverter()
  final ProposalEntity proposal;
  final String createdAt;

  ///distance km for list
  final String distanceKm;

  final String description;
  final String audio;
  @ImageEntityConverter()
  final List<ImageEntity> images;

  /// distance for details;
  final String distance;

  const OrderEntity({
    this.id = -1,
    this.orderTitle = '',
    this.price = '',
    this.status = '',
    this.selectedMechanic,
    this.proposal = const ProposalEntity(),
    this.createdAt = '',
    this.distanceKm = '',
    this.description = '',
    this.audio = '',
    this.images = const [],
    this.distance = '',
  });

  @override
  List<Object?> get props => [
        id,
        orderTitle,
        price,
        status,
        selectedMechanic,
        proposal,
        createdAt,
        distanceKm,
        description,
        audio,
        images,
        distance,
      ];
}

class OrderEntityConverter implements JsonConverter<OrderEntity, Map<String, dynamic>> {
  const OrderEntityConverter();

  @override
  OrderEntity fromJson(Map<String, dynamic> json) {
    return OrderModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(OrderEntity entity) {
    return {
      'id': entity.id,
      'order_title': entity.orderTitle,
      'price': entity.price,
      'status': entity.status,
      'selected_mechanic': entity.selectedMechanic,
      'proposal': ProposalEntityConverter().toJson(entity.proposal),
      'created_at': entity.createdAt,
      'distance_km': entity.distanceKm,
      'description': entity.description,
      'audio': entity.audio,
      'images': entity.images.map((e) => ImageEntityConverter().toJson(e)).toList(),
      'distance': entity.distance,
    };
  }
}

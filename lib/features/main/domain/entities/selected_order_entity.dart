import 'package:equatable/equatable.dart';
import 'package:mechanic/features/main/domain/entities/map_entity.dart';

class SelectedOrderEntity extends Equatable {
  final int orderId;
  final String orderTitle;
  final String orderAddress;
  final double orderPrice;
  final double proposalPrice;
  final int acceptedTime;
  final double mechanicLat;
  @MapEntityConverter()
  final MapEntity map;

  const SelectedOrderEntity({
    this.orderId = -1,
    this.orderTitle = '',
    this.orderAddress = '',
    this.orderPrice = 0.0,
    this.proposalPrice = 0.0,
    this.acceptedTime = 0,
    this.mechanicLat = 0.0,
    this.map = const MapEntity(),
  });

  @override
  List<Object?> get props => [
        orderId,
        orderTitle,
        orderAddress,
        orderPrice,
        proposalPrice,
        acceptedTime,
        mechanicLat,
        map,
      ];
}

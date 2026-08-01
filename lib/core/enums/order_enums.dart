import 'package:json_annotation/json_annotation.dart';

enum OrderStatus {
  pending,
  mechanicSelected,
  accepted,
  arrived,
  inProgress,
  completed,
  canceled,
  mechanicDone;

  bool get isPending => this == OrderStatus.pending;

  bool get isMechanicSelected => this == OrderStatus.mechanicSelected;

  bool get isAccepted => this == OrderStatus.accepted;

  bool get isArrived => this == OrderStatus.arrived;

  bool get isInProgress => this == OrderStatus.inProgress;

  bool get isCompleted => this == OrderStatus.completed;

  bool get isCanceled => this == OrderStatus.canceled;

  bool get isMechanicDone => this == OrderStatus.mechanicDone;

  String get key {
    switch (this) {
      case OrderStatus.pending:
        return 'new';
      case OrderStatus.mechanicSelected:
        return 'mechanic_selected';
      case OrderStatus.accepted:
        return 'accepted';
      case OrderStatus.arrived:
        return 'arrived';
      case OrderStatus.inProgress:
        return 'in_progress';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.canceled:
        return 'canceled';
      case OrderStatus.mechanicDone:
        return 'mechanic_done';
    }
  }

  String get orderDescription {
    switch (this) {
      case OrderStatus.pending:
        return "New order created successfully. Waiting for masters to accept it.";
      case OrderStatus.mechanicSelected:
        return 'Waiting for the master to accept the order...';
      case OrderStatus.accepted:
        return 'The master accepted the order and is on the way to you!';
      case OrderStatus.arrived:
        //write in uzbek
        return 'The master has arrived at your location. Work will start shortly.';
      case OrderStatus.inProgress:
        //write in uzbek
        return 'Your order is being worked on.';
      case OrderStatus.completed:
        return 'Your order has been completed successfully.';
      case OrderStatus.canceled:
        return 'Your order was cancelled.';
      case OrderStatus.mechanicDone:
        return 'The master finished the work, please proceed with payment.';
    }
  }
}

class OrderStatusConverter implements JsonConverter<OrderStatus, String> {
  const OrderStatusConverter();

  @override
  OrderStatus fromJson(String json) {
    return OrderStatus.values.firstWhere((e) => e.key == json, orElse: () => OrderStatus.pending);
  }

  @override
  String toJson(OrderStatus object) {
    return object.key;
  }
}

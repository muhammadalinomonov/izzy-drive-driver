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
        return "Yangi buyurtma muaffaqiyatli yaratildi. Ustalar uni qabul qilishlari kutilmoqda.";
      case OrderStatus.mechanicSelected:
        return 'Usta buyurtma qabul qilishi kutilmoqda...';
      case OrderStatus.accepted:
        return 'Usta buyurtmani qabul qildi, va siz tomon harakatlanmoqda!';
      case OrderStatus.arrived:
        //write in uzbek
        return 'Usta sizning manzilingizga yetib keldi. Tez orada ish boshlanadi.';
      case OrderStatus.inProgress:
        //write in uzbek
        return 'Sizning buyurtmangiz ustida ish olib borilmoqda.';
      case OrderStatus.completed:
        return 'Sizning buyurtmangiz muvaffaqiyatli yakunlandi.';
      case OrderStatus.canceled:
        return 'Sizning buyurtmangiz bekor qilindi.';
      case OrderStatus.mechanicDone:
        return 'Usta ishni yakunladi, to\'lovni amalga oshiring.';
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

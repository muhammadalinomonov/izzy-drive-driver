import 'package:taxi_app/core/utils/json_safe.dart';

class MechanicArrived {
  final String event;
  final DirectEventData data;

  MechanicArrived({
    required this.event,
    required this.data,
  });

  factory MechanicArrived.fromJson(Map<String, dynamic> json) {
    return MechanicArrived(
      event: toStr(json['event']),
      data: DirectEventData.fromJson(toMap(json['data'])),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event': event,
      'data': data.toJson(),
    };
  }
}

class DirectEventData {
  final String eventStatus;
  final int orderId;

  DirectEventData({
    required this.eventStatus,
    required this.orderId,
  });

  factory DirectEventData.fromJson(Map<String, dynamic> json) {
    return DirectEventData(
      eventStatus: toStr(json['event-status']),
      orderId: toInt(json['order_id']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event-status': eventStatus,
      'order_id': orderId,
    };
  }
}
class MechanicArrived {
  final String event;
  final DirectEventData data;

  MechanicArrived({
    required this.event,
    required this.data,
  });

  factory MechanicArrived.fromJson(Map<String, dynamic> json) {
    return MechanicArrived(
      event: json['event'] as String,
      data: DirectEventData.fromJson(json['data'] as Map<String, dynamic>),
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
      eventStatus: json['event-status'] as String,
      orderId: json['order_id'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event-status': eventStatus,
      'order_id': orderId,
    };
  }
}

// File: lib/data/model/order_accepted.dart
import 'package:equatable/equatable.dart';

class OrderAccepted extends Equatable {
  final DateTime acceptedAt;
  final String eventStatus;
  final Maps maps;
  final int mechanicId;
  final String mechanicPhone;
  final String? mechanicPhoto;
  final int orderId;
  final String status;

  const OrderAccepted({
    required this.acceptedAt,
    required this.eventStatus,
    required this.maps,
    required this.mechanicId,
    required this.mechanicPhone,
    this.mechanicPhoto,
    required this.orderId,
    required this.status,
  });

  factory OrderAccepted.fromJson(Map<String, dynamic> json) {
    return OrderAccepted(
      acceptedAt: DateTime.parse(json['accepted_at'] as String),
      eventStatus: json['event-status'] as String,
      maps: Maps.fromJson(json['maps'] as Map<String, dynamic>),
      mechanicId: json['mechanic_id'] as int,
      mechanicPhone: json['mechanic_phone'] as String,
      mechanicPhoto: json['mechanic_photo'] as String?,
      orderId: json['order_id'] as int,
      status: json['status'] as String,
    );
  }

  @override
  List<Object?> get props => [
    acceptedAt,
    eventStatus,
    maps,
    mechanicId,
    mechanicPhone,
    mechanicPhoto,
    orderId,
    status,
  ];
}

class Maps extends Equatable {
  final double distanceKm;
  final double durationMin;
  final Point endPoint;
  final List<Point> route;
  final Point startPoint;

  const Maps({
    required this.distanceKm,
    required this.durationMin,
    required this.endPoint,
    required this.route,
    required this.startPoint,
  });

  factory Maps.fromJson(Map<String, dynamic> json) {
    return Maps(
      distanceKm: (json['distance_km'] as num).toDouble(),
      durationMin: (json['duration_min'] as num).toDouble(),
      endPoint: Point.fromJson(json['end_point'] as Map<String, dynamic>),
      route: (json['route'] as List)
          .map((point) => Point.fromJson(point as Map<String, dynamic>))
          .toList(),
      startPoint: Point.fromJson(json['start_point'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [
    distanceKm,
    durationMin,
    endPoint,
    route,
    startPoint,
  ];
}

class Point extends Equatable {
  final double lat;
  final double lng;

  const Point({
    required this.lat,
    required this.lng,
  });

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [lat, lng];
}
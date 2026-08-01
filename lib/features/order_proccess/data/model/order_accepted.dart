// File: lib/data/model/order_accepted.dart
import 'package:equatable/equatable.dart';
import 'package:taxi_app/core/utils/json_safe.dart';

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
      acceptedAt: DateTime.tryParse(toStr(json['accepted_at'])) ?? DateTime.now(),
      eventStatus: toStr(json['event-status']),
      maps: Maps.fromJson(toMap(json['maps'])),
      mechanicId: toInt(json['mechanic_id']),
      mechanicPhone: toStr(json['mechanic_phone']),
      mechanicPhoto: toStrNullable(json['mechanic_photo']),
      orderId: toInt(json['order_id']),
      status: toStr(json['status']),
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
      distanceKm: toDouble(json['distance_km']),
      durationMin: toDouble(json['duration_min']),
      endPoint: Point.fromJson(toMap(json['end_point'])),
      route: toList(json['route'], (e) => Point.fromJson(toMap(e))),
      startPoint: Point.fromJson(toMap(json['start_point'])),
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
      lat: toDouble(json['lat']),
      lng: toDouble(json['lng']),
    );
  }

  @override
  List<Object?> get props => [lat, lng];
}
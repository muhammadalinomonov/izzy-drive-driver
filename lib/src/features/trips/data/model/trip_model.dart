import 'package:taxi_app/src/core/utils/json_safe.dart';

/// Models for `GET mobile/toll-routes` (Quadrix Tolling).
///
/// Shapes follow `docs/mobile-api.md` §4. Only the fields the trip-history UI
/// actually renders are modelled; the toll API returns considerably more per
/// alternative (per-toll markers, OSRM maneuvers) that the detail screen can
/// pick up later.
///
/// Money always arrives as minor units + currency — see [TripMoney].

/// A monetary amount in minor units (cents), as returned by the toll API.
class TripMoney {
  final int amountMinor;
  final String currency;

  const TripMoney({required this.amountMinor, required this.currency});

  factory TripMoney.fromJson(Map<String, dynamic> json) {
    return TripMoney(
      amountMinor: toInt(json['amount_minor']),
      currency: toStr(json['currency'], 'USD'),
    );
  }

  double get amount => amountMinor / 100;

  /// `$132.00`, or `132.00 EUR` for currencies without a known symbol.
  String get formatted {
    final value = amount.toStringAsFixed(2);
    return switch (currency.toUpperCase()) {
      'USD' => '\$$value',
      'EUR' => '€$value',
      'GBP' => '£$value',
      final other => '$value $other',
    };
  }
}

class TripCoordinate {
  final double lat;
  final double lng;

  const TripCoordinate({required this.lat, required this.lng});

  factory TripCoordinate.fromJson(Map<String, dynamic> json) {
    return TripCoordinate(
      lat: toDouble(json['lat']),
      lng: toDouble(json['lng']),
    );
  }
}

class TripVehicle {
  final String id;
  final String unitNumber;
  final String licensePlate;
  final String licenseState;
  final String make;
  final String model;

  const TripVehicle({
    required this.id,
    required this.unitNumber,
    required this.licensePlate,
    required this.licenseState,
    required this.make,
    required this.model,
  });

  factory TripVehicle.fromJson(Map<String, dynamic> json) {
    return TripVehicle(
      id: toStr(json['id']),
      unitNumber: toStr(json['unit_number']),
      licensePlate: toStr(json['license_plate']),
      licenseState: toStr(json['license_state']),
      make: toStr(json['make']),
      model: toStr(json['model']),
    );
  }

  /// `Freightliner Cascadia` / `TRK-1042` when make+model are missing.
  String get displayName {
    final parts = [make, model].where((p) => p.isNotEmpty).join(' ');
    return parts.isNotEmpty ? parts : unitNumber;
  }
}

class TripAlternative {
  final String id;
  final List<String> labels;
  final int distanceMeters;
  final int durationSeconds;
  final TripMoney? toll;
  final TripMoney? total;

  const TripAlternative({
    required this.id,
    required this.labels,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.toll,
    required this.total,
  });

  factory TripAlternative.fromJson(Map<String, dynamic> json) {
    final costs = toMap(json['costs']);
    TripMoney? money(String key) {
      final raw = costs[key];
      if (raw == null) return null;
      return TripMoney.fromJson(toMap(raw));
    }

    return TripAlternative(
      id: toStr(json['id']),
      labels: toList(json['labels'], (e) => toStr(e)),
      distanceMeters: toInt(json['distance_meters']),
      durationSeconds: toInt(json['duration_seconds']),
      toll: money('toll'),
      total: money('total'),
    );
  }
}

enum TripStatus {
  calculating,
  calculated,
  failed,
  unknown;

  static TripStatus parse(String raw) {
    return switch (raw.toLowerCase()) {
      'calculating' => TripStatus.calculating,
      'calculated' => TripStatus.calculated,
      'failed' => TripStatus.failed,
      _ => TripStatus.unknown,
    };
  }
}

/// One entry of the driver's toll-route history (`RouteRequest` in the API doc).
class TripModel {
  final String id;
  final TripStatus status;
  final TripCoordinate? origin;
  final TripCoordinate? destination;
  final DateTime? departureAt;
  final DateTime? createdAt;
  final TripVehicle? vehicle;
  final List<TripAlternative> alternatives;
  final String recommendedAlternativeId;

  const TripModel({
    required this.id,
    required this.status,
    required this.origin,
    required this.destination,
    required this.departureAt,
    required this.createdAt,
    required this.vehicle,
    required this.alternatives,
    required this.recommendedAlternativeId,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic raw) {
      final value = toStrNullable(raw);
      return value == null ? null : DateTime.tryParse(value);
    }

    final originRaw = json['origin'];
    final destinationRaw = json['destination'];
    final vehicleRaw = json['vehicle'];

    return TripModel(
      id: toStr(json['id']),
      status: TripStatus.parse(toStr(json['status'])),
      origin: originRaw == null
          ? null
          : TripCoordinate.fromJson(toMap(originRaw)),
      destination: destinationRaw == null
          ? null
          : TripCoordinate.fromJson(toMap(destinationRaw)),
      departureAt: parseDate(json['departure_at']),
      createdAt: parseDate(json['created_at']),
      vehicle: vehicleRaw == null ? null : TripVehicle.fromJson(toMap(vehicleRaw)),
      alternatives: toList(
        json['alternatives'],
        (e) => TripAlternative.fromJson(toMap(e)),
      ),
      recommendedAlternativeId: toStr(json['recommended_alternative_id']),
    );
  }

  /// The alternative the server recommended, falling back to the first one so
  /// the tile always has numbers to show when a route did calculate.
  TripAlternative? get primaryAlternative {
    if (alternatives.isEmpty) return null;
    for (final alt in alternatives) {
      if (alt.id == recommendedAlternativeId) return alt;
    }
    return alternatives.first;
  }
}

/// One page of trip history plus the API's pagination block.
class TripPage {
  final List<TripModel> items;
  final int page;
  final int perPage;
  final int total;
  final int lastPage;

  const TripPage({
    required this.items,
    required this.page,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  bool get hasMore => page < lastPage;

  /// Envelope is `{ status, success, data: { items: [...] }, pagination }`.
  factory TripPage.fromJson(Map<String, dynamic> json) {
    final data = toMap(json['data']);
    final pagination = toMap(json['pagination']);
    return TripPage(
      items: toList(data['items'], (e) => TripModel.fromJson(toMap(e))),
      page: toInt(pagination['page'], 1),
      perPage: toInt(pagination['per_page'], 20),
      total: toInt(pagination['total']),
      lastPage: toInt(pagination['last_page'], 1),
    );
  }
}

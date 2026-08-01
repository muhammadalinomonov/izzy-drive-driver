import 'package:taxi_app/core/utils/json_safe.dart';

/// A truck assigned to the driver (`GET mobile/vehicles`, docs §3.4).
///
/// Only the identifying fields are modelled. The app needs this purely to
/// learn the `vehicle_id` that `POST mobile/locations` requires; the truck
/// profile (axles, weight, height) belongs to route calculation, which the
/// backend already applies server-side.
class VehicleModel {
  final String id;
  final String unitNumber;
  final String licensePlate;
  final String licenseState;
  final String make;
  final String model;
  final int year;
  final String status;

  const VehicleModel({
    required this.id,
    required this.unitNumber,
    required this.licensePlate,
    required this.licenseState,
    required this.make,
    required this.model,
    required this.year,
    required this.status,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: toStr(json['id']),
      unitNumber: toStr(json['unit_number']),
      licensePlate: toStr(json['license_plate']),
      licenseState: toStr(json['license_state']),
      make: toStr(json['make']),
      model: toStr(json['model']),
      year: toInt(json['year']),
      status: toStr(json['status']),
    );
  }

  bool get isActive => status.toLowerCase() == 'active';

  /// Best human-readable label, falling back through the fields most likely
  /// to be populated.
  String get label {
    if (unitNumber.isNotEmpty) return unitNumber;
    if (licensePlate.isNotEmpty) return licensePlate;
    return [make, model].where((p) => p.isNotEmpty).join(' ');
  }
}

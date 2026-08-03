import 'package:taxi_app/core/utils/json_safe.dart';

/// The signed-in driver on the Quadrix Tolling backend
/// (`GET/PATCH mobile/profile`, docs §3.2/§3.3).
///
/// Distinct from the legacy [ProfileModel], which models the izzydrive
/// account (email, photo, truck images, mechanic linkage). Both exist for now:
/// the old endpoints stay live until they are retired, so this is additive
/// rather than a replacement.
class DriverProfileModel {
  final String id;
  final String driverNumber;
  final String firstName;
  final String lastName;
  final String fullName;
  final String phone;
  final String licenseNumber;
  final String licenseState;
  final String status;
  final DateTime? createdAt;

  /// Premium entitlement.
  ///
  /// NOTE: `is_paid_user` is not in `docs/mobile-api.md` §3.2 as written - the
  /// documented response stops at `created_at`. It is parsed leniently so the
  /// app works either way: absent or unparseable means `false`, i.e. a regular
  /// user, which is the safe default for gating paid features.
  final bool isPaidUser;

  const DriverProfileModel({
    required this.id,
    required this.driverNumber,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.phone,
    required this.licenseNumber,
    required this.licenseState,
    required this.status,
    required this.createdAt,
    required this.isPaidUser,
  });

  factory DriverProfileModel.fromJson(Map<String, dynamic> json) {
    final created = toStrNullable(json['created_at']);
    return DriverProfileModel(
      id: toStr(json['id']),
      driverNumber: toStr(json['driver_number']),
      firstName: toStr(json['first_name']),
      lastName: toStr(json['last_name']),
      fullName: toStr(json['full_name']),
      phone: toStr(json['phone']),
      licenseNumber: toStr(json['license_number']),
      licenseState: toStr(json['license_state']),
      status: toStr(json['status']),
      createdAt: created == null ? null : DateTime.tryParse(created),
      isPaidUser: toBool(json['is_paid_user']),
    );
  }

  bool get isActive => status.toLowerCase() == 'active';

  /// Best display name, falling back through the fields most likely to be set
  /// so the header never renders blank.
  String get displayName {
    if (fullName.trim().isNotEmpty) return fullName.trim();
    final joined = [firstName, lastName]
        .where((p) => p.trim().isNotEmpty)
        .join(' ')
        .trim();
    if (joined.isNotEmpty) return joined;
    return driverNumber;
  }

  /// `D12345678 (PA)`, or just the number when no state came back.
  String get licenseLabel {
    if (licenseNumber.isEmpty) return '';
    return licenseState.isEmpty
        ? licenseNumber
        : '$licenseNumber ($licenseState)';
  }

  DriverProfileModel copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? licenseNumber,
    String? licenseState,
  }) {
    return DriverProfileModel(
      id: id,
      driverNumber: driverNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName,
      phone: phone ?? this.phone,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseState: licenseState ?? this.licenseState,
      status: status,
      createdAt: createdAt,
      isPaidUser: isPaidUser,
    );
  }
}

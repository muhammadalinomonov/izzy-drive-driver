import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/profile/data/model/driver_profile_model.dart';
import 'package:taxi_app/features/trips/data/model/vehicle_model.dart';

/// Quadrix Tolling driver profile (docs §3.2-§3.4).
///
/// Kept alongside [ProfileRepository] rather than replacing it: the izzydrive
/// endpoints stay live until they are retired.
abstract class DriverProfileRepository {
  Future<NetworkResponse<DriverProfileModel>> fetchProfile();

  /// Partial update — pass only the fields being changed.
  Future<NetworkResponse<DriverProfileModel>> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? licenseNumber,
    String? licenseState,
  });

  Future<NetworkResponse<List<VehicleModel>>> fetchVehicles();
}

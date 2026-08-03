import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/profile/data/model/driver_profile_model.dart';
import 'package:taxi_app/features/profile/data/source/driver_profile_data_source.dart';
import 'package:taxi_app/features/profile/domain/repository/driver_profile_repository.dart';
import 'package:taxi_app/features/trips/data/model/vehicle_model.dart';

class DriverProfileRepositoryImpl extends DriverProfileRepository {
  final DriverProfileDataSource dataSource;

  DriverProfileRepositoryImpl({required this.dataSource});

  @override
  Future<NetworkResponse<DriverProfileModel>> fetchProfile() {
    return dataSource.fetchProfile();
  }

  @override
  Future<NetworkResponse<DriverProfileModel>> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? licenseNumber,
    String? licenseState,
  }) {
    return dataSource.updateProfile(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      licenseNumber: licenseNumber,
      licenseState: licenseState,
    );
  }

  @override
  Future<NetworkResponse<List<VehicleModel>>> fetchVehicles() {
    return dataSource.fetchVehicles();
  }
}

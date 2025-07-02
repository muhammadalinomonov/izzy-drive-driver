import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/features/truck_info/data/source/driver_info_source.dart';
import 'package:taxi_app/src/features/truck_info/domain/repo/driver_info_repo.dart';

class DriverInfoRepoImpl extends DriverInfoRepo {
  final DriverInfoSource _driverInfoSource;

  DriverInfoRepoImpl({required DriverInfoSource driverInfoSource})
    : _driverInfoSource = driverInfoSource;

  @override
  Future<NetworkResponse> getTrackMarks() {
    return _driverInfoSource.getTrackMars();
  }

  @override
  Future<NetworkResponse> getTrackModels(String id) {
    return _driverInfoSource.getTrackModel(id);
  }
}

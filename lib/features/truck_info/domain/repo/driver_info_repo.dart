import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/truck_info/data/model/driver_info_put_model.dart';

abstract class DriverInfoRepo {
  Future<NetworkResponse> getTrackMarks();
  Future<NetworkResponse> getTrackModels(String id);
  Future<NetworkResponse> putDriverInfo(DriverInfoPutModel data);
}

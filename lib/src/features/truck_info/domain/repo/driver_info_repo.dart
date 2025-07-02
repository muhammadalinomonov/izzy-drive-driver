import 'package:taxi_app/src/core/network/network_response.dart';

abstract class DriverInfoRepo {
  Future<NetworkResponse> getTrackMarks();
  Future<NetworkResponse> getTrackModels(String id);
}

import 'package:taxi_app/src/core/network/network_response.dart';

abstract class MasterRepository {
  Future<NetworkResponse> fetchMasters({
    required double lat,
    required double long,
    required int pageSize,
  });
}

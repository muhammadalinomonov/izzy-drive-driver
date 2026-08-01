import 'package:taxi_app/core/network/network_response.dart';

abstract class MasterRepository {
  Future<NetworkResponse> fetchMasters({required double lat, required double long, required int pageSize});

  Future<NetworkResponse> getMasterDetail({required int id, double? lat, double? long});

  Future<NetworkResponse> getMasterReviews({required String  url});
}

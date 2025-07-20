import 'package:taxi_app/src/core/network/network_response.dart';

import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<NetworkResponse> getProfile();
}

import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/features/auth/data/model/auth_model.dart';

abstract class AuthRepo {
  Future<NetworkResponse> register(AuthModel authModel);
  Future<NetworkResponse> logIn(AuthModel authModel);
}

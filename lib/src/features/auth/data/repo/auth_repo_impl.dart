import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/features/auth/data/model/auth_model.dart';
import 'package:taxi_app/src/features/auth/data/source/auth_data_source.dart';
import 'package:taxi_app/src/features/auth/domain/repo/auth_repo.dart';

class AuthRepoImpl extends AuthRepo {
  final AuthDataSource authDataSource;

  AuthRepoImpl({required this.authDataSource});

  @override
  Future<NetworkResponse> logIn(AuthModel authModel) =>
      authDataSource.logIn(authModel);

  @override
  Future<NetworkResponse> register(AuthModel authModel) =>
      authDataSource.register(authModel);
}

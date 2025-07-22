import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/features/master/domain/repository/master_repository.dart';

import '../model/master_model.dart';
import '../source/master_remote_data_source.dart';

class MasterRepositoryImpl extends MasterRepository {
  final MasterRemoteDataSource remoteDataSource;
  MasterRepositoryImpl(this.remoteDataSource);

  @override
  Future<NetworkResponse> fetchMasters({required double lat ,required double long,required int pageSize}) {
    return remoteDataSource.fetchMasters(lat: 3, long: 3);
  }
}

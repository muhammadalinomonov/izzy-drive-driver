import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/master/domain/repository/master_repository.dart';

import '../source/master_remote_data_source.dart';

class MasterRepositoryImpl extends MasterRepository {
  final MasterRemoteDataSource remoteDataSource;

  MasterRepositoryImpl(this.remoteDataSource);

  @override
  Future<NetworkResponse> fetchMasters({required double lat, required double long, required int pageSize}) {
    print('MasterRepositoryImpl $lat $long');
    return remoteDataSource.fetchMasters(lat: lat, long: long);
  }

  @override
  Future<NetworkResponse> getMasterDetail({required int id, double? lat, double? long}) {
    return remoteDataSource.getMasterDetail(masterId: id, lat: lat, long: long);
  }

  @override
  Future<NetworkResponse> getMasterReviews({required String url}) async {
    return remoteDataSource.getMasterReviews(url: url);
  }
}

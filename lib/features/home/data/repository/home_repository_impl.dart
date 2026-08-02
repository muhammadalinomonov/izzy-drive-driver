import 'package:injectable/injectable.dart';
import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/home/data/source/home_data_source.dart';
import 'package:taxi_app/features/home/domain/repository/home_repository.dart';

@LazySingleton(as: HomeRepository)
class HomeRepositoryImpl extends HomeRepository {
  final HomeDataSource _dataSource;

  HomeRepositoryImpl({required HomeDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<NetworkResponse> getBanners() {
    return _dataSource.getBanners();
  }

  @override
  Future<NetworkResponse> getProsal(int id) => _dataSource.getProposal(id);

  @override
  Future<NetworkResponse> selectProposal(int proposalId) {
    return _dataSource.selectProposal(proposalId);
  }
}

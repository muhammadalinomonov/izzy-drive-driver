import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/features/home/data/source/home_data_source.dart';
import 'package:taxi_app/src/features/home/domain/repository/home_repository.dart';

class HomeRepositoryImpl extends HomeRepository {
  final HomeDataSource _dataSource;

  HomeRepositoryImpl({required HomeDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<NetworkResponse> getBanners() {
    return _dataSource.getBanners();
  }
}

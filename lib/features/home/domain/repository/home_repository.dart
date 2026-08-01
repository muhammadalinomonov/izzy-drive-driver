import 'package:taxi_app/core/network/network_response.dart';

abstract class HomeRepository {
  Future<NetworkResponse> getBanners();
  Future<NetworkResponse> getProsal(int id);
  Future<NetworkResponse> selectProposal( int proposalId);
}

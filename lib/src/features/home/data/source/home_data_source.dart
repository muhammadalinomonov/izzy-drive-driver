import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/extensions/status_code_extension.dart';
import 'package:taxi_app/src/core/network/api_constants.dart';
import 'package:taxi_app/src/core/network/dio_model.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/core/utils/json_safe.dart';

class HomeDataSource {
  final client = serviceLocator.get<DioSettings>().dio;
  Future<NetworkResponse> getBanners() async {
    try {
      final response = await client.get(ApiConstants.getBanners);
      if (response.isSuccess) {
        print('Banner came ${response.data}');
        return NetworkResponse(data: response.data);
      } else {
        print('Banner error ${response.data}');
        return NetworkResponse(errorText: response.statusMessage ?? '');
      }
    } on DioException catch (e) {
      print(e.response?.data);
      return NetworkResponse(
        errorText: dioErrorMessage(e.response?.data, 'Dio exception error'),
      );
    } catch (e) {
      return NetworkResponse(errorText: e.toString());
    }
  }

  // ! get-proposal
  Future<NetworkResponse> getProposal(int id) async {
    try {
      final token = StorageRepository.getString('token');
      final url = '${ApiConstants.getProposals}$id';
      print(
        'DEBUG: Token being used: '
        ' [32m$token [0m',
      );
      print(
        'DEBUG: Full request URL: '
        ' [34m${client.options.baseUrl}$url [0m',
      );
      final response = await client.get(
        url,
        options: Options(headers: {'Authorization': "Bearer $token"}),
      );
      if (response.isSuccess) {
        print('Get proposals ${response.data}');
        return NetworkResponse(data: response.data);
      } else {
        print('Get proposal error ${response.data}');
        return NetworkResponse(errorText: response.statusMessage ?? '');
      }
    } on DioException catch (e) {
      print('Dio exception status code proposal: ${e.response?.statusCode}');
      print('Dio exception response body proposal: ${e.response?.data}');
      return NetworkResponse(
        errorText: dioErrorMessage(e.response?.data, 'Dio exception error'),
      );
    } catch (e) {
      return NetworkResponse(errorText: e.toString());
    }
  }
  Future<NetworkResponse> selectProposal(int proposalId) async {
    try {
      final token = StorageRepository.getString('token');
      final url = ApiConstants.selectProposal;
      print(
        'DEBUG: Token being used: [32m$token [0m',
      );
      print(
        'DEBUG: Full request URL: [34m${client.options.baseUrl}$url [0m',
      );
      final response = await client.post(
        url,
        data: {'proposal_id': proposalId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.isSuccess) {
        print('Select proposal success ${response.data}');
        final routeData = response.data['route'] as Map<String, dynamic>?;
        return NetworkResponse(data: routeData ?? response.data);
      } else {
        print('Select proposal error ${response.data}');
        return NetworkResponse(errorText: response.statusMessage ?? '');
      }
    } on DioException catch (e) {
      print('Dio exception status code select: ${e.response?.statusCode}');
      print('Dio exception response body select: ${e.response?.data}');
      return NetworkResponse(
        errorText: dioErrorMessage(e.response?.data, 'Dio exception error'),
      );
    } catch (e) {
      return NetworkResponse(errorText: e.toString());
    }
  }
}

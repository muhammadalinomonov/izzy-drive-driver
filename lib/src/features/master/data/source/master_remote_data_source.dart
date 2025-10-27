import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/extensions/status_code_extension.dart';
import 'package:taxi_app/src/core/network/api_constants.dart';
import 'package:taxi_app/src/core/network/dio_model.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/features/master/data/model/review_model.dart';

import '../model/master_model.dart';

class MasterRemoteDataSource {
  MasterRemoteDataSource();

  final client = serviceLocator.get<DioSettings>().dio;

  Future<NetworkResponse> fetchMasters({required double lat, required double long, int pageSize = 100}) async {
    try {
      print('Fetching masters from remote data source $lat $long');
      final response = await client.get(
        ApiConstants.mastersView,
        queryParameters: {'driver_lat': lat, 'driver_long': long, 'page_size': pageSize},
      );
      print('Received response from remote data source');
      if (response.isSuccess) {
        print('Response is successful');
        final data = response.data['data'] as List;
        return NetworkResponse(data: data.map((e) => MasterModel.fromJson(e)).toList());
      } else {
        print('Response is not successful');
        return NetworkResponse(errorText: response.data['message'] ?? 'Something went wrong try again');
      }
    } on DioException catch (e) {
      print('Dio exception occurred: ${e.message}');
      return NetworkResponse(errorText: e.response?.data['message'] ?? 'Something went wrong');
    } catch (e) {
      print('Unknown error occurred: $e');
      return NetworkResponse(errorText: 'Something went wrong');
    }
  }

  Future<NetworkResponse> getMasterDetail({required int masterId, double? lat, double? long}) async {
    try {
      final response = await client.get(
        ApiConstants.masterDetail,
        queryParameters: {'mechanic_id': masterId, 'driver_lat': lat, 'driver_long': long},
      );
      if (response.isSuccess) {
        final data = response.data['data'];
        return NetworkResponse(data: MasterModel.fromJson(data));
      } else {
        return NetworkResponse(errorText: response.data['message'] ?? 'Something went wrong try again');
      }
    } on DioException catch (e) {
      return NetworkResponse(errorText: e.response?.data['message'] ?? 'Something went wrong');
    } catch (e) {
      return NetworkResponse(errorText: 'Something went wrong');
    }
  }

  Future<NetworkResponse> getMasterReviews({required String url}) async {
    try {
      final response = await client.get(url);
      if (response.isSuccess) {
        final data = response.data['data']['data'] as List;
        return NetworkResponse(data: data.map((e) => ReviewModel.fromJson(e)).toList());
      } else {
        return NetworkResponse(errorText: response.data['message'] ?? 'Something went wrong try again');
      }
    } on DioException catch (e) {
      return NetworkResponse(errorText: e.response?.data['message'] ?? 'Something went wrong');
    } catch (e) {
      return NetworkResponse(errorText: 'Something went wrong');
    }
  }
}

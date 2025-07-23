import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/extensions/status_code_extension.dart';
import 'package:taxi_app/src/core/network/api_constants.dart';
import 'package:taxi_app/src/core/network/dio_model.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import '../model/master_model.dart';

class MasterRemoteDataSource {
  MasterRemoteDataSource();

  final client = serviceLocator.get<DioSettings>().dio;

  Future<NetworkResponse> fetchMasters({
    required double lat,
    required double long,
    int pageSize = 5,
  }) async {
    try {
      print('Fetching masters from remote data source $lat $long');
      final response = await client.get(
        ApiConstants.mastersView,
        queryParameters: {
          'driver_lat': lat,
          'driver_long': long,
          'page_size': pageSize,
        },
      );
      print('Received response from remote data source');
      if (response.isSuccess) {
        print('Response is successful');
        final data = response.data['data'] as List;
        return NetworkResponse(
          data: data.map((e) => MasterModel.fromJson(e)).toList(),
        );
      } else {
        print('Response is not successful');
        return NetworkResponse(
          errorText:
              response.data['message'] ?? 'Something went wrong try again',
        );
      }
    } on DioException catch (e) {
      print('Dio exception occurred: ${e.message}');
      return NetworkResponse(
        errorText: e.response?.data['message'] ?? 'Something went wrong',
      );
    } catch (e) {
      print('Unknown error occurred: $e');
      return NetworkResponse(errorText: 'Something went wrong');
    }
  }
}

import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/extensions/status_code_extension.dart';
import 'package:taxi_app/src/core/network/api_constants.dart';
import 'package:taxi_app/src/core/network/dio_model.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/core/service_locater.dart';

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
        errorText: e.response?.data['message'] ?? 'Dio exception error',
      );
    } catch (e) {
      return NetworkResponse(errorText: e.toString());
    }
  }
}

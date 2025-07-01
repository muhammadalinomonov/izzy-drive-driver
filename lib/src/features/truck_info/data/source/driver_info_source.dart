import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/extensions/status_code_extension.dart';
import 'package:taxi_app/src/core/network/api_constants.dart';
import 'package:taxi_app/src/core/network/dio_model.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/core/service_locater.dart';

class DriverInfoSource {
  Future<NetworkResponse> getTrackMars() async {
    final client = serviceLocator.get<DioSettings>().dio;

    try {
      final response = await client.get(
        ApiConstants.getTrackMarks,
        options: Options(
          headers: {
            'Authorization': "Bearer ${StorageRepository.getString('token')}",
          },
        ),
      );

      if (response.isSuccess) {
        print('Success on get Marks');
        print(response.data);
        return NetworkResponse(data: response.data);
      } else {
        print('error on register ${response.statusCode}');
        print(response.data);
        return NetworkResponse(errorText: response.statusMessage ?? "");
      }
    } on DioException catch (e) {
      return NetworkResponse(
        errorText: e.response?.data ?? 'Dio exception error',
      );
    } catch (e) {
      return NetworkResponse(errorText: e.toString());
    }
  }

  Future<NetworkResponse> getTrackModel(String id) async {
    final client = serviceLocator.get<DioSettings>().dio;

    try {
      final response = await client.get(
        '${ApiConstants.getTrackModel}?mark_id=$id',
        options: Options(
          headers: {
            'Authorization': "Bearer ${StorageRepository.getString('token')}",
          },
        ),
      );

      if (response.isSuccess) {
        print('Success on get Models');
        print(response.data);
        return NetworkResponse(data: response.data);
      } else {
        print('error on register ${response.statusCode}');
        print(response.data);
        return NetworkResponse(errorText: response.statusMessage ?? "");
      }
    } on DioException catch (e) {
      return NetworkResponse(
        errorText: e.response?.data ?? 'Dio exception error',
      );
    } catch (e) {
      return NetworkResponse(errorText: e.toString());
    }
  }
}

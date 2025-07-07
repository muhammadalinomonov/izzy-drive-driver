import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/extensions/status_code_extension.dart';
import 'package:taxi_app/src/core/network/api_constants.dart';
import 'package:taxi_app/src/core/network/dio_model.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/features/truck_info/data/model/driver_info_put_model.dart';
import 'package:taxi_app/src/features/truck_info/domain/model/track_model.dart';

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
        return NetworkResponse(
          data: response.data['data'] != null
              ? TruckMarkResponse.fromJson(response.data)
              : [],
        );
      } else {
        print('error on track get ${response.statusCode}');
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
        return NetworkResponse(
          data: response.data['data'] != null
              ? TruckModelResponse.fromJson(response.data)
              : [],
        );
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

  Future<NetworkResponse> putDriverInfo(DriverInfoPutModel data) async {
    final client = serviceLocator.get<DioSettings>().dio;
    try {
      final response = await client.put(
        ApiConstants.driverInfo,
        options: Options(
          headers: {
            'Authorization': "Bearer ${StorageRepository.getString('token')}",
          },
        ),
        data: FormData.fromMap(data.toJson()),
      );
      if (response.isSuccess) {
        print('Success on put data');
        print(response.data);
        return NetworkResponse(data: response.data);
      } else {
        print('error on put data ${response.statusCode}');
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

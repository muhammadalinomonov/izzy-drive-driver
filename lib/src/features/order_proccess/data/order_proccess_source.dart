import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/extensions/status_code_extension.dart';
import 'package:taxi_app/src/core/network/api_constants.dart';
import 'package:taxi_app/src/core/network/dio_model.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/core/utils/json_safe.dart';
import 'package:taxi_app/src/features/order_proccess/data/model/current_order_model.dart';

import '../../profile/data/model/profile_model.dart';

class OrderProccessSource {
  OrderProccessSource();

  final client = serviceLocator.get<DioSettings>().dio;

  Future<NetworkResponse> getMe() async {
    try {
      final token = StorageRepository.getString('token');
      final response = await client.get(
        ApiConstants.profileGet,
        options: Options(headers: {'Authorization': "Bearer $token"}),
      );
      if (response.isSuccess) {
        print('Profile fetched successfully: ${response.data}');
        var profileModel = ProfileModel.fromJson(toMap(response.data['data']));
        final wsId = profileModel.wsId;
        StorageRepository.putInt("ws_id", wsId);
        return NetworkResponse(data: profileModel);
      } else {
        print('Error fetching profile: ${response.data}');
        return NetworkResponse(errorText: dioErrorMessage(response.data, 'Something went wrong try again'));
      }
    } on DioException catch (e) {
      print('Dio exception fetching profile: ${e.response?.statusCode}');
      print('Dio exception response body: ${e.response?.data}');
      return NetworkResponse(errorText: dioErrorMessage(e.response?.data, 'Something went wrong'));
    } catch (e) {
      print('Error fetching profile: $e');
      return NetworkResponse(errorText: 'Something went wrong');
    }
  }

  Future<NetworkResponse<void>> cancelOrder() async {
    try {
      final token = StorageRepository.getString('token');

      final response = await client.post(
        ApiConstants.activeOrder,
        data: {'action': 'cancel'},
        options: Options(
          headers: {'Authorization': "Bearer $token", 'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      if (response.isSuccess) {
        return NetworkResponse(data: null);
      } else {
        return NetworkResponse(errorText: dioErrorMessage(response.data, 'Unexpected status: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      return NetworkResponse(errorText: dioErrorMessage(e.response?.data, e.message ?? 'Cancel failed'));
    } catch (e) {
      return NetworkResponse(errorText: e.toString());
    }
  }

  Future<NetworkResponse<CurrentOrderModel>> getCurrentOrder() async {
    try {
      final token = StorageRepository.getString('token');

      final response = await client.get(
        ApiConstants.currentOrder,

        options: Options(
          headers: {'Authorization': "Bearer $token", 'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      if (response.statusCode == 200) {
        final currentOrder = CurrentOrderModel.fromJson(toMap(response.data['data']));
        return NetworkResponse<CurrentOrderModel>(data: currentOrder);
      } else {
        return NetworkResponse<CurrentOrderModel>(errorText: 'Unexpected status code: ${response.statusCode}');
      }
    } catch (e) {
      return NetworkResponse<CurrentOrderModel>(errorText: e.toString());
    }
  }

  Future<NetworkResponse<void>> changeSubOrderStatus({required String status, required int id}) async {
    try {
      final token = StorageRepository.getString('token').replaceAll('Bearer', '').trim();

      final result = await client.post(
        ApiConstants.subOrderStatus,
        data: {'status': status, 'suborder_id': id},
        options: Options(
          headers: {'Authorization': "Bearer $token", 'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );
      return NetworkResponse(data: null);
    } catch (e) {
      return NetworkResponse(errorText: e.toString());
    }
  }

  Future<NetworkResponse<int>> doneCurrentOrder() async {
    try {
      final token = StorageRepository.getString('token').replaceAll('Bearer', '').trim();

      final result = await client.post(
        ApiConstants.doneCurrentOrder,
        data: {'status': 'done'},
        options: Options(
          headers: {'Authorization': "Bearer $token", 'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );
      if (result.isSuccess) {
        final dataMap = toMap(result.data['data']);
        return NetworkResponse(data: toInt(dataMap['code']));
      } else {
        return NetworkResponse(errorText: dioErrorMessage(result.data, 'Something went wrong'));
      }
    } catch (e) {
      return NetworkResponse(errorText: e.toString());
    }
  }

  Future<NetworkResponse<void>> rateMaster(int star, String comment, int mechanicId) async {
    try {
      final token = StorageRepository.getString('token').replaceAll('Bearer', '').trim();

      final result = await client.post(
        ApiConstants.rateMaster,
        data: {'stars': star, 'comment': comment, 'mechanic_id': mechanicId},
        options: Options(
          headers: {'Authorization': "Bearer $token", 'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );
      if (result.isSuccess) {
        return NetworkResponse(data: null);
      } else {
        return NetworkResponse(errorText: dioErrorMessage(result.data, 'Something went wrong'));
      }
    } catch (e) {
      return NetworkResponse(errorText: e.toString());
    }
  }
}

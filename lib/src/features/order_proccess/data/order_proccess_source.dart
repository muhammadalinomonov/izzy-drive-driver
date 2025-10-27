import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/extensions/status_code_extension.dart';
import 'package:taxi_app/src/core/network/api_constants.dart';
import 'package:taxi_app/src/core/network/dio_model.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/features/order_proccess/data/model/current_order_model.dart';

import '../../profile/data/model/profile_model.dart';
import 'model/cancel_order_response.dart';

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
        var profileModel = ProfileModel.fromJson(response.data['data']);
        StorageRepository.putInt("ws_id", profileModel.wsId);
        return NetworkResponse(data: ProfileModel.fromJson(response.data['data']));
      } else {
        print('Error fetching profile: ${response.data}');
        return NetworkResponse(errorText: response.data['message'] ?? 'Something went wrong try again');
      }
    } on DioException catch (e) {
      print('Dio exception fetching profile: ${e.response?.statusCode}');
      print('Dio exception response body: ${e.response?.data}');
      return NetworkResponse(errorText: e.response?.data['message'] ?? 'Something went wrong');
    } catch (e) {
      print('Error fetching profile: $e');
      return NetworkResponse(errorText: 'Something went wrong');
    }
  }

  Future<NetworkResponse<CancelOrderResponse>> cancelOrder(String orderId) async {
    try {
      final token = StorageRepository.getString('token');

      final response = await client.post(
        ApiConstants.cancelOrder,
        data: {'order_id': orderId, 'status': 'cancel'},
        options: Options(
          headers: {'Authorization': "Bearer $token", 'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      if (response.statusCode == 200) {
        final cancelResponse = CancelOrderResponse.fromJson(response.data);
        return NetworkResponse<CancelOrderResponse>(data: cancelResponse);
      } else {
        return NetworkResponse<CancelOrderResponse>(errorText: 'Unexpected status code: ${response.statusCode}');
      }
    } catch (e) {
      return NetworkResponse<CancelOrderResponse>(errorText: e.toString());
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
        final currentOrder = CurrentOrderModel.fromJson(response.data['data']);
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
        return NetworkResponse(data: result.data['data']['code']);
      } else {
        return NetworkResponse(errorText: result.data['message'] ?? 'Something went wrong');
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
        return NetworkResponse(errorText: result.data['message'] ?? 'Something went wrong');
      }
    } catch (e) {
      return NetworkResponse(errorText: e.toString());
    }
  }
}

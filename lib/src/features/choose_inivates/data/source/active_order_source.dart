import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/extensions/status_code_extension.dart';

import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_model.dart';
import '../../../../core/network/network_response.dart';
import '../../../../core/network/token_service.dart';
import '../../../../core/service_locater.dart';
import '../model/active_order.dart';

class ActiveOrderSource {
  final client = serviceLocator.get<DioSettings>().dio;

  Future<NetworkResponse> fetchActiveOrder() async {
    try {
      var token = StorageRepository.getString("token");
      final response = await client.get(
        ApiConstants.fetchActiveOffers,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.isSuccess) {
        print('Success on fetching active order');
        print(response.data);
        final orderResponse = OrderResponse.fromJson(response.data);
        return NetworkResponse(data: orderResponse);
      } else {
        print('Error on fetching active order ${response.statusCode}');
        print(response.data);
        return NetworkResponse(errorText: response.statusMessage ?? "");
      }
    } on DioException catch (e) {
      print('Dio error: ${e.response?.data ?? e.message}');
      return NetworkResponse(errorText: e.response?.data ?? 'Dio exception error');
    } catch (e) {
      print('General error: $e');
      return NetworkResponse(errorText: e.toString());
    }
  }

  Future<NetworkResponse> updateOrderPrice(double orderPrice) async {
    try {
      var token = StorageRepository.getString("token");
      final response = await client.post(
        ApiConstants.fetchActiveOffers,
        data: {'action': 'update_price', 'new_price': orderPrice},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.isSuccess) {
        print('Success on fetching active order');
        print(response.data);
        final orderResponse = OrderResponse.fromJson(response.data);
        return NetworkResponse(data: orderResponse);
      } else {
        print('Error on fetching active order ${response.statusCode}');
        print(response.data);
        return NetworkResponse(errorText: response.statusMessage ?? "");
      }
    } on DioException catch (e) {
      print('Dio error: ${e.response?.data ?? e.message}');
      return NetworkResponse(errorText: e.response?.data ?? 'Dio exception error');
    } catch (e) {
      print('General error: $e');
      return NetworkResponse(errorText: e.toString());
    }
  }
}

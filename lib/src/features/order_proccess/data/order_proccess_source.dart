import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/extensions/status_code_extension.dart';
import 'package:taxi_app/src/core/network/api_constants.dart';
import 'package:taxi_app/src/core/network/dio_model.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/core/service_locater.dart';
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
        return NetworkResponse(
          data: ProfileModel.fromJson(response.data['data']),
        );
      } else {
        print('Error fetching profile: ${response.data}');
        return NetworkResponse(
          errorText:
              response.data['message'] ?? 'Something went wrong try again',
        );
      }
    } on DioException catch (e) {
      print('Dio exception fetching profile: ${e.response?.statusCode}');
      print('Dio exception response body: ${e.response?.data}');
      return NetworkResponse(
        errorText: e.response?.data['message'] ?? 'Something went wrong',
      );
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
        data: {
          'order_id': orderId,
          'status': 'cancel',
        },
        options: Options(
          headers: {
            'Authorization': "Bearer $token",
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      if (response.statusCode == 200) {
        final cancelResponse = CancelOrderResponse.fromJson(response.data);
        return NetworkResponse<CancelOrderResponse>(
          data: cancelResponse,
        );
      } else {
        return NetworkResponse<CancelOrderResponse>(
          errorText: 'Unexpected status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      return NetworkResponse<CancelOrderResponse>(
        errorText: e.toString(),
      );
    }
  }

}

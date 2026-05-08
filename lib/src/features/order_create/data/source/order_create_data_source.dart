import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/extensions/status_code_extension.dart';
import 'package:taxi_app/src/core/network/api_constants.dart';
import 'package:taxi_app/src/core/network/dio_model.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/features/order_create/data/model/order_create_request_model.dart';
import 'package:taxi_app/src/features/order_create/data/model/order_create_response_model.dart';

class OrderCreateDataSource {
  OrderCreateDataSource();

  final _client = serviceLocator.get<DioSettings>().dio;

  Future<NetworkResponse<OrderCreateResponseModel>> createOrder(
    OrderCreateRequestModel request,
  ) async {
    try {
      final token = StorageRepository.getString('token');
      final formData = await request.toFormData();

      final response = await _client.post(
        ApiConstants.createReport,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.isSuccess) {
        final body = OrderCreateResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return NetworkResponse(data: body);
      }
      return NetworkResponse(
        errorText: (response.data is Map ? response.data['message'] : null)
                ?.toString() ??
            'Unexpected status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map ? data['message']?.toString() : null;
      return NetworkResponse(errorText: msg ?? e.message ?? 'Could not send order');
    } catch (e) {
      return NetworkResponse(errorText: e.toString());
    }
  }
}

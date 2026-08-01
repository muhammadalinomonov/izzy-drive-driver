import 'package:dio/dio.dart';
import 'package:taxi_app/core/extensions/status_code_extension.dart';
import 'package:taxi_app/core/network/api_constants.dart';
import 'package:taxi_app/core/network/dio_model.dart';
import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/core/network/token_service.dart';
import 'package:taxi_app/core/service_locater.dart';
import 'package:taxi_app/features/order_create/data/model/order_create_request_model.dart';
import 'package:taxi_app/features/order_create/data/model/order_create_response_model.dart';
import 'package:taxi_app/features/order_create/data/model/question_template_model.dart';

class OrderCreateDataSource {
  OrderCreateDataSource();

  final _client = serviceLocator.get<DioSettings>().dio;

  Future<NetworkResponse<List<QuestionTemplate>>> fetchQuestions() async {
    try {
      final token = StorageRepository.getString('token');
      final response = await _client.get(
        ApiConstants.fetchQuestions,
        options: Options(
          headers: {if (token.isNotEmpty) 'Authorization': 'Bearer $token'},
        ),
      );
      if (response.isSuccess) {
        final raw = response.data;
        // CustomResponse.ok wraps the payload as { status, message, data: [...] }.
        // Fall back to the top-level list if a different shape is returned.
        final List list = (raw is Map && raw['data'] is List)
            ? raw['data'] as List
            : raw is List
                ? raw
                : const [];
        final items = list
            .whereType<Map<String, dynamic>>()
            .map(QuestionTemplate.fromJson)
            .where((q) => q.type != QuestionType.unknown)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
        return NetworkResponse(data: items);
      }
      return NetworkResponse(
        errorText: 'Unexpected status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      return NetworkResponse(errorText: e.message ?? 'Could not load questions');
    } catch (e) {
      return NetworkResponse(errorText: e.toString());
    }
  }

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

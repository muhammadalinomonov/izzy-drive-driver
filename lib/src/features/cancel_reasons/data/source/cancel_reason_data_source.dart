import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/extensions/status_code_extension.dart';
import 'package:taxi_app/src/core/network/api_constants.dart';
import 'package:taxi_app/src/core/network/dio_model.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/core/utils/json_safe.dart';
import 'package:taxi_app/src/features/cancel_reasons/data/model/cancel_reason_model.dart';

class CancelReasonDataSource {
  CancelReasonDataSource();

  final client = serviceLocator.get<DioSettings>().dio;

  Future<NetworkResponse<List<CancelReasonModel>>> fetch({
    String audience = 'driver',
  }) async {
    try {
      final token = StorageRepository.getString('token');
      final response = await client.get(
        ApiConstants.cancelReasons,
        queryParameters: {'audience': audience},
        options: Options(headers: {'Authorization': "Bearer $token"}),
      );
      if (response.isSuccess) {
        final reasons = toList(
          response.data is Map ? response.data['data'] : null,
          (e) => CancelReasonModel.fromJson(toMap(e)),
        );
        // Backend already returns the rows pre-sorted by `order`, but be
        // defensive in case that ever changes.
        reasons.sort((a, b) => a.order.compareTo(b.order));
        return NetworkResponse<List<CancelReasonModel>>(data: reasons);
      }
      return NetworkResponse<List<CancelReasonModel>>(
        errorText: dioErrorMessage(response.data, 'Server xatosi'),
      );
    } on DioException catch (e) {
      return NetworkResponse<List<CancelReasonModel>>(
        errorText: dioErrorMessage(e.response?.data, e.message ?? 'Tarmoq xatosi'),
      );
    } catch (e) {
      return NetworkResponse<List<CancelReasonModel>>(errorText: e.toString());
    }
  }
}

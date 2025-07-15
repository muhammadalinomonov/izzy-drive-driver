import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/extensions/status_code_extension.dart';
import 'package:taxi_app/src/core/network/api_constants.dart';
import 'package:taxi_app/src/core/network/dio_model.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/core/service_locater.dart';

import '../model/question_model.dart';
import '../model/report_model.dart';
import '../model/report_response.dart';

class ChatDataSource {
  final client = serviceLocator.get<DioSettings>().dio;

  Future<NetworkResponse> fetchQuestions() async {
    try {
      final response = await client.get(ApiConstants.fetchQuestions);

      if (response.isSuccess) {
        print('Success on fetching questions');
        print(response.data);
        final questionTemplate = QuestionTemplate.fromJson(response.data);
        return NetworkResponse(data: questionTemplate);
      } else {
        print('Error on fetching questions ${response.statusCode}');
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

  Future<NetworkResponse> createReport(ReportModel reportModel) async {
    try {
      final formData = reportModel.toFormData();
      var token = StorageRepository.getString("token");
      final response = await client.post(
        ApiConstants.createReport,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.isSuccess) {
        print('Success on creating report');
        print('Response data type: ${response.data.runtimeType}'); // Turini tekshirish
        print('Response data: ${response.data}');
        // JSON ni ReportResponse ga parse qilish
        final reportResponse = ReportResponse.fromJson(response.data);
        print('Parsed ReportResponse: $reportResponse');
        return NetworkResponse(data: reportResponse);
      } else {
        print('Error on creating report ${response.statusCode}');
        print('Response data: ${response.data}');
        return NetworkResponse(errorText: response.statusMessage ?? "");
      }
    } on DioException catch (e) {
      print('Dio error: ${e.response?.data ?? e.message}');
      return NetworkResponse(
        errorText: e.response?.data ?? 'Dio exception error',
      );
    } catch (e) {
      print('General error: $e');
      return NetworkResponse(errorText: e.toString());
    }
  }
}

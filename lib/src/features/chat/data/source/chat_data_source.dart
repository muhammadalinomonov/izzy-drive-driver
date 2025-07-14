import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/extensions/status_code_extension.dart';
import 'package:taxi_app/src/core/network/api_constants.dart';
import 'package:taxi_app/src/core/network/dio_model.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/core/service_locater.dart';

import '../model/question_model.dart';

class ChatDataSource {
  final client = serviceLocator.get<DioSettings>().dio;

  Future<NetworkResponse> fetchQuestions() async {
    try {
      final response = await client.get(
        ApiConstants.fetchQuestions,
      );

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
}
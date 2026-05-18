import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/features/order_create/data/model/order_create_request_model.dart';
import 'package:taxi_app/src/features/order_create/data/model/order_create_response_model.dart';
import 'package:taxi_app/src/features/order_create/data/model/question_template_model.dart';

abstract class OrderCreateRepo {
  Future<NetworkResponse<OrderCreateResponseModel>> createOrder(
    OrderCreateRequestModel request,
  );

  Future<NetworkResponse<List<QuestionTemplate>>> fetchQuestions();
}

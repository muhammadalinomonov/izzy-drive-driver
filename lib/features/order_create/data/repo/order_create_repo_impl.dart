import 'package:injectable/injectable.dart';
import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/order_create/data/model/order_create_request_model.dart';
import 'package:taxi_app/features/order_create/data/model/order_create_response_model.dart';
import 'package:taxi_app/features/order_create/data/model/question_template_model.dart';
import 'package:taxi_app/features/order_create/data/source/order_create_data_source.dart';
import 'package:taxi_app/features/order_create/domain/repo/order_create_repo.dart';

@LazySingleton(as: OrderCreateRepo)
class OrderCreateRepoImpl implements OrderCreateRepo {
  OrderCreateRepoImpl({required this.dataSource});

  final OrderCreateDataSource dataSource;

  @override
  Future<NetworkResponse<OrderCreateResponseModel>> createOrder(
    OrderCreateRequestModel request,
  ) {
    return dataSource.createOrder(request);
  }

  @override
  Future<NetworkResponse<List<QuestionTemplate>>> fetchQuestions() {
    return dataSource.fetchQuestions();
  }
}

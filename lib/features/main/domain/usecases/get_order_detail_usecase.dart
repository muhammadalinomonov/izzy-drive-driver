import 'package:mechanic/core/exceptions/failures.dart';
import 'package:mechanic/core/usecases/use_case.dart';
import 'package:mechanic/core/utils/either.dart';
import 'package:mechanic/features/common/data/models/base_model.dart';
import 'package:mechanic/features/main/domain/entities/order_detail_entity.dart';
import 'package:mechanic/features/main/domain/repositories/orders_repository.dart';

class GetOrderDetailUseCase implements UseCase<BaseModel<OrderDetailEntity>, int> {
  final OrdersRepository repository;

  GetOrderDetailUseCase({required this.repository});

  @override
  Future<Either<Failure, BaseModel<OrderDetailEntity>>> call(int params) async {
    return await repository.getOrderDetail(params);
  }
}

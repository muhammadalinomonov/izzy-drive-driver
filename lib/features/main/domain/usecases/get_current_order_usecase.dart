import 'package:mechanic/core/exceptions/failures.dart';
import 'package:mechanic/core/usecases/use_case.dart';
import 'package:mechanic/core/utils/either.dart';
import 'package:mechanic/features/common/data/models/base_model.dart';
import 'package:mechanic/features/main/domain/entities/current_order_entity.dart';
import 'package:mechanic/features/main/domain/repositories/orders_repository.dart';

class GetCurrentOrderUseCase implements UseCase<BaseModel<CurrentOrderEntity>, NoParams> {
  final OrdersRepository repository;

  GetCurrentOrderUseCase({required this.repository});

  @override
  Future<Either<Failure, BaseModel<CurrentOrderEntity>>> call(NoParams params) async {
    return await repository.getCurrentOrder();
  }
}

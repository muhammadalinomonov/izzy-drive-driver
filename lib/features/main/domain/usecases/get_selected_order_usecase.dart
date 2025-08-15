import 'package:mechanic/core/exceptions/failures.dart';
import 'package:mechanic/core/usecases/use_case.dart';
import 'package:mechanic/core/utils/either.dart';
import 'package:mechanic/features/common/data/models/base_model.dart';
import 'package:mechanic/features/main/domain/entities/selected_order_entity.dart';
import 'package:mechanic/features/main/domain/repositories/orders_repository.dart';

class GetSelectedOrderUseCase implements UseCase<BaseModel<SelectedOrderEntity>, int> {
  final OrdersRepository repository;

  GetSelectedOrderUseCase({required this.repository});

  @override
  Future<Either<Failure, BaseModel<SelectedOrderEntity>>> call(int params) async {
    return await repository.getSelectedOrder(params);
  }
}

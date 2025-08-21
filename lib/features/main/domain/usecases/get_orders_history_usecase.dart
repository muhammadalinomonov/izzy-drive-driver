import 'package:mechanic/core/exceptions/failures.dart';
import 'package:mechanic/core/usecases/use_case.dart';
import 'package:mechanic/core/utils/either.dart';
import 'package:mechanic/features/common/data/models/generic_pagination.dart';
import 'package:mechanic/features/main/domain/entities/order_with_date_entity.dart';
import 'package:mechanic/features/main/domain/repositories/orders_repository.dart';

class GetOrdersHistoryUseCase implements UseCase<GenericPagination<OrdersWithDataEntity>, String?> {
  final OrdersRepository repository;

  GetOrdersHistoryUseCase({required this.repository});

  @override
  Future<Either<Failure, GenericPagination<OrdersWithDataEntity>>> call(String? params) async {
    return await repository.getOrdersHistory(next: params);
  }
}

import 'package:mechanic/core/exceptions/failures.dart';
import 'package:mechanic/core/usecases/use_case.dart';
import 'package:mechanic/core/utils/either.dart';
import 'package:mechanic/features/common/data/models/generic_pagination.dart';
import 'package:mechanic/features/main/domain/entities/order_entity.dart';
import 'package:mechanic/features/main/domain/repositories/orders_repository.dart';

class GetOrdersUseCase implements UseCase<GenericPagination<OrderEntity>, (String? next, bool? isSelected)> {
  final OrdersRepository repository;

  GetOrdersUseCase({required this.repository});

  @override
  Future<Either<Failure, GenericPagination<OrderEntity>>> call((String? next, bool? isSelected) params) async {
    return await repository.getOrders(next: params.$1, isSelected: params.$2);
  }
}

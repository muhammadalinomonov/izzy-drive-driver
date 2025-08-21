import 'package:mechanic/core/exceptions/failures.dart';
import 'package:mechanic/core/usecases/use_case.dart';
import 'package:mechanic/core/utils/either.dart';
import 'package:mechanic/features/main/domain/repositories/orders_repository.dart';

class ChangeOrderStatusUseCase implements UseCase<void, ({int orderId, String status,  String? code})> {
  final OrdersRepository repository;

  ChangeOrderStatusUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(({int orderId, String status, String? code}) params) async {
    return await repository.changeOrderStatus(
      orderId: params.orderId,
      status: params.status,
      code: params.code,
    );
  }
}

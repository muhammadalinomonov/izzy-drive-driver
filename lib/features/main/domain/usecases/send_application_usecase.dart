import 'package:mechanic/core/exceptions/failures.dart';
import 'package:mechanic/core/usecases/use_case.dart';
import 'package:mechanic/core/utils/either.dart';
import 'package:mechanic/features/main/domain/repositories/orders_repository.dart';

class SendApplicationUseCase implements UseCase<void, ({int orderId, String? comment, String price})> {
  final OrdersRepository repository;

  SendApplicationUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(({int orderId, String? comment, String price}) params) async {
    return await repository.sendApplication(
      orderId: params.orderId,
      comment: params.comment,
      proposedPrice: params.price,
    );
  }
}

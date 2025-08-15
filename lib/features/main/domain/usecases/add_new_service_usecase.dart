import 'package:mechanic/core/exceptions/failures.dart';
import 'package:mechanic/core/usecases/use_case.dart';
import 'package:mechanic/core/utils/either.dart';
import 'package:mechanic/features/main/domain/repositories/orders_repository.dart';

class AddNewServiceUseCase implements UseCase<void, ({String title, double price})> {
  final OrdersRepository repository;

  AddNewServiceUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(({String title, double price}) params) async {
    return await repository.addNewService(
      title: params.title,
      price: params.price,
    );
  }
}

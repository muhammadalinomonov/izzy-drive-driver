import 'package:mechanic/core/exceptions/failures.dart';
import 'package:mechanic/core/usecases/use_case.dart';
import 'package:mechanic/core/utils/either.dart';
import 'package:mechanic/features/auth/domain/repositories/auth_repository.dart';

class LogoutUseCase implements UseCase<void, String> {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) async {
    return await repository.logout(params);
  }
}
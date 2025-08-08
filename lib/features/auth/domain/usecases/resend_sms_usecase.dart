import 'package:mechanic/core/exceptions/failures.dart';
import 'package:mechanic/core/usecases/use_case.dart';
import 'package:mechanic/core/utils/either.dart';
import 'package:mechanic/features/auth/domain/repositories/auth_repository.dart';

class ResendSmsUseCase implements UseCase<void, String> {
  final AuthRepository repository;

  ResendSmsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) async {
    return await repository.resendSms(params);
  }
}
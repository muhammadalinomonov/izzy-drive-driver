import 'package:mechanic/core/exceptions/failures.dart';
import 'package:mechanic/core/usecases/use_case.dart';
import 'package:mechanic/core/utils/either.dart';
import 'package:mechanic/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase implements UseCase<String , (String, String)> {
  final AuthRepository repository;

  LoginUseCase({required this.repository});

  @override
  Future<Either<Failure, String>> call(params) async {
    return await repository.login(params.$1, params.$2);
  }
}




import 'package:mechanic/core/exceptions/failures.dart';
import 'package:mechanic/core/usecases/use_case.dart';
import 'package:mechanic/core/utils/either.dart';
import 'package:mechanic/features/auth/domain/entities/user_entity.dart';
import 'package:mechanic/features/auth/domain/repositories/auth_repository.dart';

class GetUserDataUseCase implements UseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  GetUserDataUseCase({required this.repository});

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) {
    return repository.getUserData();
  }
}
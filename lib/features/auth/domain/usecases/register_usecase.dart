import 'package:mechanic/core/exceptions/failures.dart';
import 'package:mechanic/core/usecases/use_case.dart';
import 'package:mechanic/core/utils/either.dart';
import 'package:mechanic/features/auth/domain/repositories/auth_repository.dart';

class RegisterUseCase implements UseCase<void, ({String email, String password, String fullName, String fcmToken})> {
  final AuthRepository repository;

  RegisterUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(({String email, String password, String fullName, String fcmToken}) params) async {
    return await repository.register(
        fcmToken: params.fcmToken, email: params.email, password: params.password, fullName: params.fullName);
  }
}

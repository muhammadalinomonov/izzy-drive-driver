import 'package:mechanic/core/usecases/use_case.dart';
import 'package:mechanic/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mechanic/features/auth/domain/repositories/auth_repository.dart';

class GetAuthStatusUseCase implements StreamUseCase<AuthenticationStatus, NoParams> {
  final AuthRepository repository;

  GetAuthStatusUseCase({required this.repository});

  @override
  Stream<AuthenticationStatus> call(NoParams params) => repository.statusStream();
}

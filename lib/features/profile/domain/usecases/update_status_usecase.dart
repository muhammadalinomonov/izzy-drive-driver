import 'package:mechanic/core/exceptions/failures.dart';
import 'package:mechanic/core/usecases/use_case.dart';
import 'package:mechanic/core/utils/either.dart';
import 'package:mechanic/features/profile/domain/repositories/profile_repository.dart';

class UpdateStatusUseCase implements UseCase<void, bool> {
  final ProfileRepository repository;

  UpdateStatusUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(bool params) async {
    return await repository.updateStatus(isOnline: params);
  }
}

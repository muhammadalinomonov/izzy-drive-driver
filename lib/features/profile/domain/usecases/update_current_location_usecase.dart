import 'package:mechanic/core/exceptions/failures.dart';
import 'package:mechanic/core/usecases/use_case.dart';
import 'package:mechanic/core/utils/either.dart';
import 'package:mechanic/features/profile/domain/repositories/profile_repository.dart';

class UpdateCurrentLocationUseCase implements UseCase<void, (double lattitude, double longtitude)> {
  final ProfileRepository repository;

  UpdateCurrentLocationUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call((double lattitude, double longtitude) params) async {
    return await repository.updateCurrentLocation(latitude: params.$1, longitude: params.$2);
  }
}

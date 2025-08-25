import 'package:mechanic/core/exceptions/failures.dart';
import 'package:mechanic/core/utils/either.dart';
import 'package:mechanic/features/profile/domain/entities/static_entity.dart';

abstract class ProfileRepository {
  Future<Either<Failure, void>> updateStatus({required bool isOnline});

  Future<Either<Failure, void>> updateCurrentLocation({
    required double latitude,
    required double longitude,
  });

  Future<Either<Failure, List<StatisticEntity>>> getUserStatistic({required String filter, required String period});
}

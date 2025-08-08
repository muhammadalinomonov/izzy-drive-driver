import 'package:mechanic/core/exceptions/failures.dart';
import 'package:mechanic/core/utils/either.dart';

abstract class ProfileRepository{
  Future<Either<Failure, void>> updateStatus({required bool isOnline});
  Future<Either<Failure, void>> updateCurrentLocation({
    required double latitude,
    required double longitude,
  });
}
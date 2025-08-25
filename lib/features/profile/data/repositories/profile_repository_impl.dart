import 'package:mechanic/core/exceptions/exceptions.dart';
import 'package:mechanic/core/exceptions/failures.dart';
import 'package:mechanic/core/utils/either.dart';
import 'package:mechanic/features/profile/data/datasources/profile_datasource.dart';
import 'package:mechanic/features/profile/domain/entities/static_entity.dart';
import 'package:mechanic/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl extends ProfileRepository {
  final ProfileDataSource dataSource;

  ProfileRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, void>> updateCurrentLocation({required double latitude, required double longitude}) async {
    try {
      final result = await dataSource.updateCurrentLocation(latitude: latitude, longitude: longitude);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.errorMessage, statusCode: e.statusCode));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(errorMessage: e.errorMessage));
    } catch (e) {
      return Left(ParsingFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateStatus({required bool isOnline}) async {
    try {
      final result = await dataSource.updateStatus(isOnline: isOnline);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.errorMessage, statusCode: e.statusCode));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(errorMessage: e.errorMessage));
    } catch (e) {
      return Left(ParsingFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<StatisticEntity>>> getUserStatistic({
    required String filter,
    required String period,
  }) async {
    try {
      final result = await dataSource.getUserStatistic(filter: filter, period: period);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.errorMessage, statusCode: e.statusCode));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(errorMessage: e.errorMessage));
    } catch (e) {
      return Left(ParsingFailure(errorMessage: e.toString()));
    }
  }
}

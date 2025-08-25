import 'package:mechanic/core/exceptions/failures.dart';
import 'package:mechanic/core/usecases/use_case.dart';
import 'package:mechanic/core/utils/either.dart';
import 'package:mechanic/features/profile/domain/entities/static_entity.dart';
import 'package:mechanic/features/profile/domain/repositories/profile_repository.dart';

class GetUserStatisticsUseCase implements UseCase<List<StatisticEntity>, ({String filter, String period})> {
  final ProfileRepository repository;

  GetUserStatisticsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<StatisticEntity>>> call(({String filter, String period}) params) async {
    return await repository.getUserStatistic(filter: params.filter, period: params.period);
  }
}

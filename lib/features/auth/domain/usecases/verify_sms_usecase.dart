import 'package:mechanic/core/exceptions/failures.dart';
import 'package:mechanic/core/usecases/use_case.dart';
import 'package:mechanic/core/utils/either.dart';
import 'package:mechanic/features/auth/domain/entities/user_entity.dart';
import 'package:mechanic/features/auth/domain/repositories/auth_repository.dart';

class VerifySmsUseCase implements UseCase<UserEntity, VerifySmsParams> {
  final AuthRepository repository;

  VerifySmsUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(VerifySmsParams params) async {
    return await repository.verifySms(params.token, params.code, params.deviceName, params.fcmToken, params.deviceId);
  }
}

class VerifySmsParams {
  final String token;
  final String code;
  final String deviceName;
  final String fcmToken;
  final String deviceId;

  VerifySmsParams({required this.token, required this.code, required this.deviceName, required this.fcmToken, required this.deviceId});
}

import 'package:mechanic/core/exceptions/failures.dart';
import 'package:mechanic/core/utils/either.dart';
import 'package:mechanic/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mechanic/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {

  Future<Either<Failure, void>> register({
    required String email,
    required String fullName,
    required String password,
    required String fcmToken,
  });
  Future<Either<Failure, UserEntity>> getUserData();

  Stream<AuthenticationStatus> statusStream();

  Future<Either<Failure, String>> login(String email, String password);

  Future<Either<Failure, void>> resendSms(String token);

  Future<Either<Failure, UserEntity>> verifySms(String token, String code, String deviceName, String fcmToken, String deviceId);

  Future<Either<Failure, void>> fillInfo({required String name});

  Future<Either<Failure, void>> logout(String deviceId);
}

/*{
    "status": true,
    "message": "Foydalanuvchi muvaffaqiyatli yaratildi",
    "data": {
        "id": 48,
        "email": "mechanic7@mail.ru",
        "full_name": "Zaylop usta",
        "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzU0NzY0NjQzLCJpYXQiOjE3NTIxNzI2NDMsImp0aSI6Ijg2MGU3MTU2YjgyMjQ5YjI4OTAzNDg5YTcwZDE5ZWIzIiwidXNlcl9pZCI6NDh9.Q5XFwwpFJr4NrWmfjnEsccjQi-BzjZDHojI8JzE5lM4",
        "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc1NDc2NDY0MywiaWF0IjoxNzUyMTcyNjQzLCJqdGkiOiI2NWQxOTYyYzRhOWM0MWRmYmJiNzg1NDY3MDJkNTZlMSIsInVzZXJfaWQiOjQ4fQ._4bIzEXwi-NoFBgEFBGZv7XffHK4S0HALUui5zwmfLk"
    }
}*/
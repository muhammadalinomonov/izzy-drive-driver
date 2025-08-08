import 'dart:async';

import 'package:mechanic/core/exceptions/exceptions.dart';
import 'package:mechanic/core/exceptions/failures.dart';
import 'package:mechanic/core/utils/either.dart';
import 'package:mechanic/features/auth/data/data_sources/auth_data_source.dart';
import 'package:mechanic/features/auth/domain/entities/user_entity.dart';
import 'package:mechanic/features/auth/domain/repositories/auth_repository.dart';

enum AuthenticationStatus { authenticated, unauthenticated }

final StreamController<AuthenticationStatus> authStreamController = StreamController<AuthenticationStatus>.broadcast(sync: true);

class AuthRepositoryImpl extends AuthRepository {
  final AuthDataSource dataSource;

  AuthRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, UserEntity>> getUserData() async {
    try {
      final result = await dataSource.getUserData();

      return Right(result.data!);
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.errorMessage, statusCode: e.statusCode));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(errorMessage: e.errorMessage));
    } catch (e) {
      return Left(ParsingFailure(errorMessage: e.toString()));
    }
  }

  @override
  Stream<AuthenticationStatus> statusStream() async* {
    try {
      final result = getUserData();
      final resultList = await Future.wait([result, Future.delayed(const Duration(milliseconds: 100))]);
      if (resultList.first.isRight) {
        yield AuthenticationStatus.authenticated;
      } else {
        yield AuthenticationStatus.unauthenticated;
      }
    } on Exception {
      authStreamController.add(AuthenticationStatus.unauthenticated);
    }
    yield* authStreamController.stream;
  }
  //eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzUzNTk4NjgwLCJpYXQiOjE3NTM1OTgwODAsImp0aSI6ImNiMTQyZjFlYTUzZTQ1YzRhMTY3YTk2ODRhMjBiZDc4IiwidXNlcl9pZCI6MjZ9.sypvlC3wDCOySS036PngAlXcxM1EyPlFg7MHOjeNE6c

  @override
  Future<Either<Failure, String>> login(String email, String password) async {
    try {
      final result = await dataSource.login(email, password);
      authStreamController.add(AuthenticationStatus.authenticated);
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
  Future<Either<Failure, void>> resendSms(String token) async {
    try {
      await dataSource.resendSms(token);
      return Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.errorMessage, statusCode: e.statusCode));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(errorMessage: e.errorMessage));
    } catch (e) {
      return Left(ParsingFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifySms(
      String token, String code, String deviceName, String fcmToken, String deviceId) async {
    try {
      final user = await dataSource.verifySms(token, code, deviceName, fcmToken, deviceId);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(errorMessage: e.errorMessage, statusCode: e.statusCode));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(errorMessage: e.errorMessage));
    } catch (e) {
      return Left(ParsingFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> fillInfo({required String name}) async {
    try {
      final result = await dataSource.fillInfo(name: name);
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
  Future<Either<Failure, void>> logout(String deviceId) async {
    try {
      final result = await dataSource.logout(deviceId);
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
  Future<Either<Failure, void>> register(
      {required String email, required String fullName, required String password, required String fcmToken}) async {
    try {
      final result =
          await dataSource.register(email: email, fullName: fullName, password: password, fcmToken: fcmToken);

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

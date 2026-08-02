import 'package:injectable/injectable.dart';
import 'dart:io';

import 'package:taxi_app/core/exeptions/failures.dart';
import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/core/utils/either.dart';
import 'package:taxi_app/features/common/data/models/generic_pagination.dart';
import 'package:taxi_app/features/order_proccess/domain/entities/current_order_entity.dart';
import 'package:taxi_app/features/profile/domain/entities/order_history_entity.dart';
import 'package:taxi_app/features/profile/domain/entities/output_entity.dart';

import '../../domain/repository/profile_repository.dart';
import '../source/profile_data_source.dart';

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileDataSource dataSource;

  ProfileRepositoryImpl(this.dataSource);

  @override
  Future<NetworkResponse> getProfile() async {
    return await dataSource.fetchProfile();
  }

  @override
  Future<NetworkResponse<String>> uploadAvatar(File file) async {
    return await dataSource.uploadAvatar(file);
  }

  @override
  Future<Either<Failure, GenericPagination<OutPutEntity>>> getAllOutputs() async {
    try {
      final result = await dataSource.getAllOutputs();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Either<Failure, void>> create(Map<String, dynamic> data) async {
    try {
      final result = await dataSource.createOutput(data);
      if (result.errorText.isNotEmpty) {
        return Left(ServerFailure(errorMessage: result.errorText, statusCode: 500));
      }
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Either<Failure, void>> updatePassword(Map<String, dynamic> data) async {
    try {
      final result = await dataSource.updatePassword(data);
      if (result.errorText.isNotEmpty) {
        return Left(ServerFailure(errorMessage: result.errorText, statusCode: 500));
      }
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Either<Failure, GenericPagination<CurrentOrderEntity>>> getOrdersHistory({String? next}) async {
    try {
      final result = await dataSource.getOrdersHistory(next: next);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString(), statusCode: 500));
    }
  }

  @override
  Future<Either<Failure, OrderHistoryEntity>> getOrderHistoryDetail({required int id}) async {
    try {
      final result = await dataSource.getOrdersHistoryDetail(id: id);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString(), statusCode: 500));
    }
  }
}

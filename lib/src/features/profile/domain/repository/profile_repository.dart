import 'package:taxi_app/src/core/exeptions/failures.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/core/utils/either.dart';
import 'package:taxi_app/src/features/common/data/models/generic_pagination.dart';
import 'package:taxi_app/src/features/order_proccess/domain/entities/current_order_entity.dart';
import 'package:taxi_app/src/features/profile/domain/entities/order_history_entity.dart';
import 'package:taxi_app/src/features/profile/domain/entities/output_entity.dart';

abstract class ProfileRepository {
  Future<NetworkResponse> getProfile();

  Future<Either<Failure, GenericPagination<OutPutEntity>>> getAllOutputs();

  Future<Either<Failure, void>> create(Map<String, dynamic> data);

  Future<Either<Failure, void>> updatePassword(Map<String, dynamic> data);

  Future<Either<Failure, GenericPagination<CurrentOrderEntity>>> getOrdersHistory({String? next});

  Future<Either<Failure, OrderHistoryEntity>> getOrderHistoryDetail({required int id});
}

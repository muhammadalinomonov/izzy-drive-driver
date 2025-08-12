import 'package:mechanic/core/exceptions/exceptions.dart';
import 'package:mechanic/core/exceptions/failures.dart';
import 'package:mechanic/core/utils/either.dart';
import 'package:mechanic/features/common/data/models/base_model.dart';
import 'package:mechanic/features/common/data/models/generic_pagination.dart';
import 'package:mechanic/features/main/data/datasources/orders_datasource.dart';
import 'package:mechanic/features/main/domain/entities/current_order_entity.dart';
import 'package:mechanic/features/main/domain/entities/order_detail_entity.dart';
import 'package:mechanic/features/main/domain/entities/order_entity.dart';
import 'package:mechanic/features/main/domain/repositories/orders_repository.dart';

class OrdersRepositoryImpl extends OrdersRepository {
  final OrdersDataSource dataSource;

  OrdersRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, BaseModel<OrderDetailEntity>>> getOrderDetail(int orderId) async {
    try {
      final result = await dataSource.getOrderDetail(orderId);
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
  Future<Either<Failure, GenericPagination<OrderEntity>>> getOrders({String? next}) async {
    try {
      final result = await dataSource.getOrders(next: next);
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
  Future<Either<Failure, void>> sendApplication(
      {required int orderId, String? comment, required String proposedPrice}) async {
    try {
      await dataSource.sendApplication(orderId: orderId, comment: comment, proposedPrice: proposedPrice);
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
  Future<Either<Failure, BaseModel<CurrentOrderEntity>>> getCurrentOrder() async {
    try {
      final result = await dataSource.getCurrentOrder();
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

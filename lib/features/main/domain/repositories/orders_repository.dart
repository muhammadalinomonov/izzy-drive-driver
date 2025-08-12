import 'package:mechanic/core/exceptions/failures.dart';
import 'package:mechanic/core/utils/either.dart';
import 'package:mechanic/features/common/data/models/base_model.dart';
import 'package:mechanic/features/common/data/models/generic_pagination.dart';
import 'package:mechanic/features/main/domain/entities/current_order_entity.dart';
import 'package:mechanic/features/main/domain/entities/order_detail_entity.dart';
import 'package:mechanic/features/main/domain/entities/order_entity.dart';

abstract class OrdersRepository {
  Future<Either<Failure, GenericPagination<OrderEntity>>> getOrders({String? next});

  Future<Either<Failure, BaseModel<OrderDetailEntity>>> getOrderDetail(int orderId);

  Future<Either<Failure, void>> sendApplication({
    required int orderId,
    String? comment,
    required String proposedPrice,
  });

  Future<Either<Failure, BaseModel<CurrentOrderEntity>>> getCurrentOrder();
}
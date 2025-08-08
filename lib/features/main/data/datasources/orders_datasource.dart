import 'package:dio/dio.dart';
import 'package:mechanic/core/exceptions/exceptions.dart';
import 'package:mechanic/features/common/data/models/base_model.dart' show BaseModel;
import 'package:mechanic/features/common/data/models/generic_pagination.dart';
import 'package:mechanic/features/main/data/models/order_detail_model.dart';
import 'package:mechanic/features/main/data/models/order_model.dart';

abstract class OrdersDataSource {
  Future<GenericPagination<OrderModel>> getOrders({String? next});

  Future<BaseModel<OrderDetailModel>> getOrderDetail(int orderId);

  Future<void> sendApplication({
    required int orderId,
    String? comment,
    required String proposedPrice,
  });
}

class OrdersDataSourceImpl implements OrdersDataSource {
  final Dio dio;

  OrdersDataSourceImpl({required this.dio});

  @override
  Future<GenericPagination<OrderModel>> getOrders({String? next}) async {
    try {
      final response = await dio.get(
        next ?? 'mechanics/get-orders/',
        queryParameters: {
          'page_size':50,
        }
      );
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return GenericPagination<OrderModel>.fromJson(
          response.data,
          (json) => OrderModel.fromJson(json),
        );
      } else {
        throw ServerException(
          errorMessage: 'Failed to fetch orders',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ParsingException(errorMessage: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<BaseModel<OrderDetailModel>> getOrderDetail(int orderId) async {
    try {
      final response = await dio.get('mechanics/orders/detail/?order_id=$orderId');

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return BaseModel.fromJson(response.data, (json) => OrderDetailModel.fromJson(json));
      } else {
        throw ServerException(
          errorMessage: 'Failed to fetch order details',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ParsingException(errorMessage: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> sendApplication({required int orderId, String? comment, required String proposedPrice}) async {
    try {
      final response = await dio.post(
        'mechanics/proposals/create/',
        data: {
          'order_id': orderId,
          if (comment != null) 'comment': comment ?? '',
          'proposed_price': proposedPrice,
        },
      );

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return;
      } else {
        throw ServerException(
          errorMessage: 'Failed to send application',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ParsingException(errorMessage: 'An unexpected error occurred: $e');
    }
  }
}

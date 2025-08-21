import 'package:dio/dio.dart';
import 'package:mechanic/core/exceptions/exceptions.dart';
import 'package:mechanic/features/common/data/models/base_model.dart' show BaseModel;
import 'package:mechanic/features/common/data/models/generic_pagination.dart';
import 'package:mechanic/features/main/data/models/current_order_model.dart';
import 'package:mechanic/features/main/data/models/order_detail_model.dart';
import 'package:mechanic/features/main/data/models/order_model.dart';
import 'package:mechanic/features/main/data/models/orders_with_date_model.dart';
import 'package:mechanic/features/main/data/models/selected_order_model.dart';

abstract class OrdersDataSource {
  Future<GenericPagination<OrderModel>> getOrders({String? next});

  Future<BaseModel<OrderDetailModel>> getOrderDetail(int orderId);

  Future<void> sendApplication({
    required int orderId,
    String? comment,
    required String proposedPrice,
  });

  Future<BaseModel<CurrentOrderModel>> getCurrentOrder();

  Future<BaseModel<SelectedOrderModel>> getSelectedOrder(int orderId);

  Future<void> addNewService({
    required String title,
    required double price,
  });

  Future<void> changeOrderStatus({
    required int orderId,
    required String status,
    String? code,
  });

  Future<GenericPagination<OrdersWithDateModel>> getOrdersHistory({String? next});

  Future<BaseModel<CurrentOrderModel>> getOrderHistoryDetail(int orderId);
}

class OrdersDataSourceImpl implements OrdersDataSource {
  final Dio dio;

  OrdersDataSourceImpl({required this.dio});

  @override
  Future<GenericPagination<OrderModel>> getOrders({String? next}) async {
    try {
      final response = await dio.get(next ?? 'mechanics/get-orders/', queryParameters: {
        'page_size': 50,
      });
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
    } on DioException {
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
    } on DioException {
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
          if (comment != null) 'comment': comment,
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
    } on DioException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ParsingException(errorMessage: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<BaseModel<CurrentOrderModel>> getCurrentOrder() async {
    try {
      final response = await dio.get('mechanics/view-current-order/');

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return BaseModel.fromJson(response.data, (json) => CurrentOrderModel.fromJson(json));
      } else {
        throw ServerException(
          errorMessage: 'Failed to fetch current order',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on DioException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ParsingException(errorMessage: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> addNewService({required String title, required double price}) async {
    try {
      final response = await dio.post(
        'mechanics/create-suborder/',
        data: {
          'title': title,
          'price': price,
        },
      );

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return;
      } else {
        throw ServerException(
          errorMessage: 'Failed to add new service',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on DioException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ParsingException(errorMessage: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> changeOrderStatus({required int orderId, required String status, String? code}) async {
    try {
      final response = await dio.post(
        'mechanics/update-order-status/',
        data: {
          'order_id': orderId,
          'status': status,
          if (code != null && status == 'completed') 'code': code,
        },
      );

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return;
      } else {
        throw ServerException(
          errorMessage: 'Failed to change order status',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on DioException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ParsingException(errorMessage: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<BaseModel<SelectedOrderModel>> getSelectedOrder(int orderId) async {
    try {
      final response = await dio.get(
        'mechanics/view-active-order/',
        queryParameters: {
          'order_id': orderId,
        },
      );

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return BaseModel.fromJson(response.data, (json) => SelectedOrderModel.fromJson(json));
      } else {
        throw ServerException(
          errorMessage: 'Failed to fetch selected order',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on DioException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ParsingException(errorMessage: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<GenericPagination<OrdersWithDateModel>> getOrdersHistory({String? next}) async {
    try {
      final response = await dio.get(
        next ?? 'mechanics/order-history/',
        queryParameters: {
          if (next == null) 'page_size': 3,
        },
      );
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return GenericPagination<OrdersWithDateModel>.fromJson(
          response.data,
          (json) => OrdersWithDateModel.fromJson(json),
        );
      } else {
        throw ServerException(
          errorMessage: 'Failed to fetch orders history',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on DioException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ParsingException(errorMessage: 'An unexpected error occurred: $e');
    }
  }

  @override
  Future<BaseModel<CurrentOrderModel>> getOrderHistoryDetail(int orderId) async {
    try {
      final response = await dio.get(
        'mechanics/order-info/',
        queryParameters: {
          'order_id': orderId,
        },
      );

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return BaseModel.fromJson(response.data, (json) => CurrentOrderModel.fromJson(json));
      } else {
        throw ServerException(
          errorMessage: 'Failed to fetch order history detail',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on DioException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ParsingException(errorMessage: 'An unexpected error occurred: $e');
    }
  }
}

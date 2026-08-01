import 'package:dio/dio.dart';
import 'package:taxi_app/core/extensions/status_code_extension.dart';
import 'package:taxi_app/core/network/api_constants.dart';
import 'package:taxi_app/core/network/dio_model.dart';
import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/core/service_locater.dart';
import 'package:taxi_app/core/utils/json_safe.dart';
import 'package:taxi_app/features/notifications/data/model/notification_model.dart';

class NotificationsDataSource {
  NotificationsDataSource();

  final client = serviceLocator.get<DioSettings>().dio;

  Future<NetworkResponse<NotificationPage>> fetchPage({
    int page = 1,
    int pageSize = 20,
    String? absoluteUrl,
  }) async {
    try {
      final response = absoluteUrl != null && absoluteUrl.isNotEmpty
          ? await client.getUri(Uri.parse(absoluteUrl))
          : await client.get(
              ApiConstants.notifications,
              queryParameters: {'page': page, 'page_size': pageSize},
            );
      if (response.isSuccess) {
        return NetworkResponse<NotificationPage>(
          data: NotificationPage.fromJson(toMap(response.data)),
        );
      }
      return NetworkResponse<NotificationPage>(
        errorText: dioErrorMessage(response.data, 'Server xatosi'),
      );
    } on DioException catch (e) {
      return NetworkResponse<NotificationPage>(
        errorText: dioErrorMessage(e.response?.data, 'Tarmoq xatosi'),
      );
    } catch (e) {
      return NetworkResponse<NotificationPage>(errorText: e.toString());
    }
  }

  Future<NetworkResponse<NotificationModel>> getDetail(int id) async {
    try {
      final response = await client.get(ApiConstants.notificationDetail(id));
      if (response.isSuccess) {
        return NetworkResponse<NotificationModel>(
          data: NotificationModel.fromJson(toMap(response.data['data'])),
        );
      }
      return NetworkResponse<NotificationModel>(
        errorText: dioErrorMessage(response.data, 'Server xatosi'),
      );
    } on DioException catch (e) {
      return NetworkResponse<NotificationModel>(
        errorText: dioErrorMessage(e.response?.data, 'Tarmoq xatosi'),
      );
    } catch (e) {
      return NetworkResponse<NotificationModel>(errorText: e.toString());
    }
  }

  Future<NetworkResponse<int>> unreadCount() async {
    try {
      final response = await client.get(ApiConstants.notificationsUnreadCount);
      if (response.isSuccess) {
        final dataMap = toMap(response.data['data']);
        return NetworkResponse<int>(data: toInt(dataMap['count']));
      }
      return NetworkResponse<int>(
        errorText: dioErrorMessage(response.data, 'Server xatosi'),
      );
    } on DioException catch (e) {
      return NetworkResponse<int>(
        errorText: dioErrorMessage(e.response?.data, 'Tarmoq xatosi'),
      );
    } catch (e) {
      return NetworkResponse<int>(errorText: e.toString());
    }
  }

  Future<NetworkResponse> markRead(int id) async {
    try {
      final response = await client.post(ApiConstants.notificationMarkRead(id));
      if (response.isSuccess) return NetworkResponse(data: response.data);
      return NetworkResponse(
        errorText: dioErrorMessage(response.data, 'Server xatosi'),
      );
    } on DioException catch (e) {
      return NetworkResponse(
        errorText: dioErrorMessage(e.response?.data, 'Tarmoq xatosi'),
      );
    } catch (e) {
      return NetworkResponse(errorText: e.toString());
    }
  }

  Future<NetworkResponse> markAllRead() async {
    try {
      final response = await client.post(ApiConstants.notificationsReadAll);
      if (response.isSuccess) return NetworkResponse(data: response.data);
      return NetworkResponse(
        errorText: dioErrorMessage(response.data, 'Server xatosi'),
      );
    } on DioException catch (e) {
      return NetworkResponse(
        errorText: dioErrorMessage(e.response?.data, 'Tarmoq xatosi'),
      );
    } catch (e) {
      return NetworkResponse(errorText: e.toString());
    }
  }
}

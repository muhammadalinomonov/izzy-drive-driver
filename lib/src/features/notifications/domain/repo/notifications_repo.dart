import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/features/notifications/data/model/notification_model.dart';

abstract class NotificationsRepo {
  Future<NetworkResponse<NotificationPage>> fetchPage({
    int page = 1,
    int pageSize = 20,
    String? absoluteUrl,
  });

  Future<NetworkResponse<NotificationModel>> getDetail(int id);

  Future<NetworkResponse<int>> unreadCount();

  Future<NetworkResponse> markRead(int id);

  Future<NetworkResponse> markAllRead();
}

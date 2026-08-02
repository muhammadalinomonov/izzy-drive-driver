import 'package:injectable/injectable.dart';
import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/notifications/data/model/notification_model.dart';
import 'package:taxi_app/features/notifications/data/source/notifications_data_source.dart';
import 'package:taxi_app/features/notifications/domain/repo/notifications_repo.dart';

@LazySingleton(as: NotificationsRepo)
class NotificationsRepoImpl extends NotificationsRepo {
  final NotificationsDataSource dataSource;

  NotificationsRepoImpl({required this.dataSource});

  @override
  Future<NetworkResponse<NotificationPage>> fetchPage({
    int page = 1,
    int pageSize = 20,
    String? absoluteUrl,
  }) {
    return dataSource.fetchPage(page: page, pageSize: pageSize, absoluteUrl: absoluteUrl);
  }

  @override
  Future<NetworkResponse<NotificationModel>> getDetail(int id) => dataSource.getDetail(id);

  @override
  Future<NetworkResponse<int>> unreadCount() => dataSource.unreadCount();

  @override
  Future<NetworkResponse> markRead(int id) => dataSource.markRead(id);

  @override
  Future<NetworkResponse> markAllRead() => dataSource.markAllRead();
}

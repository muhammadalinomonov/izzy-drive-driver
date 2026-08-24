import 'package:injectable/injectable.dart';
import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/trips/data/model/support_chat_model.dart';
import 'package:taxi_app/features/trips/data/model/support_timeline_model.dart';
import 'package:taxi_app/features/trips/data/source/support_chat_data_source.dart';
import 'package:taxi_app/features/trips/domain/repo/support_chat_repo.dart';

@LazySingleton(as: SupportChatRepo)
class SupportChatRepoImpl extends SupportChatRepo {
  final SupportChatDataSource dataSource;

  SupportChatRepoImpl({required this.dataSource});

  @override
  Future<NetworkResponse<SupportTimelinePage>> fetchTimeline({
    int page = 1,
    int perPage = 50,
  }) {
    return dataSource.fetchTimeline(page: page, perPage: perPage);
  }

  @override
  Future<NetworkResponse<SupportChatPage>> fetchHistory({
    int page = 1,
    int perPage = 50,
  }) {
    return dataSource.fetchHistory(page: page, perPage: perPage);
  }

  @override
  Future<NetworkResponse<SupportChatMessage>> sendMessage(String message) {
    return dataSource.sendMessage(message);
  }
}

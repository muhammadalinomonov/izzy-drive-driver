import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/features/trips/data/model/support_chat_model.dart';

/// Normal support chat: one conversation per driver, shared by every
/// "Support Message" entry point (docs/mobile-api.md §8.1/§8.2).
abstract class SupportChatRepo {
  /// History, newest-first. An empty page (no conversation yet) is a valid
  /// answer, not an error.
  Future<NetworkResponse<SupportChatPage>> fetchHistory({
    int page = 1,
    int perPage = 50,
  });

  /// Posts [message] and returns it as stored by the server.
  Future<NetworkResponse<SupportChatMessage>> sendMessage(String message);
}

// File: lib/src/features/chat/domain/repo/chat_repo.dart
import '../../../../core/network/network_response.dart';

abstract class ChatRepo {
  Future<NetworkResponse> fetchQuestions();
}
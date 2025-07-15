// File: lib/src/features/chat/domain/repo/chat_repo.dart
import '../../../../core/network/network_response.dart';
import '../../data/model/report_model.dart';
import '../../presentation/pages/chat_page.dart';

abstract class ChatRepo {
  Future<NetworkResponse> fetchQuestions();
  Future<NetworkResponse> createReport(ReportModel reportModel);
}
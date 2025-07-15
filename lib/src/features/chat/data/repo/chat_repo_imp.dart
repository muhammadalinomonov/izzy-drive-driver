// File: lib/src/features/chat/data/repo/chat_repo_impl.dart
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/features/chat/data/model/report_model.dart';
import 'package:taxi_app/src/features/chat/data/source/chat_data_source.dart';
import 'package:taxi_app/src/features/chat/domain/repo/chat_repo.dart';

class ChatRepoImpl extends ChatRepo {
  final ChatDataSource chatDataSource;

  ChatRepoImpl({required this.chatDataSource});

  @override
  Future<NetworkResponse> fetchQuestions() =>
      chatDataSource.fetchQuestions();

  @override
  Future<NetworkResponse> createReport(ReportModel reportModel) {
    return chatDataSource.createReport(reportModel);
  }
}
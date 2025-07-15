part of 'chat_bloc.dart';




@immutable
sealed class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object> get props => [];
}

final class ChatInitial extends ChatState {}

final class ChatLoading extends ChatState {}
final class SubmittedReport extends ChatState {
  final ReportResponse reportResponse;
  const SubmittedReport({required this.reportResponse});
}
final class ChatSuccess extends ChatState {
  final QuestionTemplate questionTemplate;

  const ChatSuccess({required this.questionTemplate});

  @override
  List<Object> get props => [questionTemplate];
}

final class ChatFailure extends ChatState {
  final String errorMessage;

  const ChatFailure({required this.errorMessage});

  @override
  List<Object> get props => [errorMessage];
}
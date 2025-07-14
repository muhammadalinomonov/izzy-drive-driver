part of 'chat_bloc.dart';




@immutable
sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class FetchQuestionsEvent extends ChatEvent {
  final VoidCallback onSuccess;
  final VoidCallback onError;

  const FetchQuestionsEvent({
    required this.onSuccess,
    required this.onError,
  });

  @override
  List<Object> get props => [onSuccess, onError];
}
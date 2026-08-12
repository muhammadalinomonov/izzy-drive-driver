part of 'support_chat_bloc.dart';

abstract class SupportChatEvent extends Equatable {
  const SupportChatEvent();

  @override
  List<Object?> get props => [];
}

/// Loads (or reloads) the conversation. Also the retry and the
/// pull-to-refresh action.
class SupportChatStarted extends SupportChatEvent {
  const SupportChatStarted();
}

/// Driver posted from the composer.
class SupportChatMessageSent extends SupportChatEvent {
  final String text;

  const SupportChatMessageSent(this.text);

  @override
  List<Object?> get props => [text];
}

part of 'support_chat_bloc.dart';

enum SupportChatStatus {
  initial,
  loading,
  ready,
  failure,

  /// Reached the page without the entitlement - see [SupportChatBloc]'s
  /// class doc. Distinct from [failure]: nothing was tried and nothing
  /// should be retried, so the UI offers no retry button here.
  restricted,
}

class SupportChatState extends Equatable {
  final SupportChatStatus status;
  final List<SupportChatMessage> messages;
  final String errorMessage;

  /// A send is in flight. Keeps the composer from posting twice.
  final bool sending;

  /// Why the last send failed. Surfaced as a snack bar, not a page state -
  /// the thread itself is still readable.
  final String sendError;

  const SupportChatState({
    this.status = SupportChatStatus.initial,
    this.messages = const [],
    this.errorMessage = '',
    this.sending = false,
    this.sendError = '',
  });

  /// A loaded thread with nothing in it - neither side has written yet.
  bool get isEmpty => status == SupportChatStatus.ready && messages.isEmpty;

  SupportChatState copyWith({
    SupportChatStatus? status,
    List<SupportChatMessage>? messages,
    String? errorMessage,
    bool? sending,
    String? sendError,
  }) {
    return SupportChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      errorMessage: errorMessage ?? this.errorMessage,
      sending: sending ?? this.sending,
      sendError: sendError ?? this.sendError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        messages,
        errorMessage,
        sending,
        sendError,
      ];
}

part of 'route_support_bloc.dart';

enum RouteSupportStatus { initial, loading, ready, failure }

class RouteSupportState extends Equatable {
  final RouteSupportStatus status;
  final List<RouteSupportMessage> messages;
  final String errorMessage;

  /// A follow-up is in flight. Keeps the composer from posting twice.
  final bool sending;

  /// Why the last send failed. Surfaced as a snack bar, not as a page state -
  /// the thread itself is still readable.
  final String sendError;

  const RouteSupportState({
    this.status = RouteSupportStatus.initial,
    this.messages = const [],
    this.errorMessage = '',
    this.sending = false,
    this.sendError = '',
  });

  /// A loaded thread with nothing in it - support has not written back and the
  /// driver has not said anything yet.
  bool get isEmpty =>
      status == RouteSupportStatus.ready && messages.isEmpty;

  RouteSupportState copyWith({
    RouteSupportStatus? status,
    List<RouteSupportMessage>? messages,
    String? errorMessage,
    bool? sending,
    String? sendError,
  }) {
    return RouteSupportState(
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

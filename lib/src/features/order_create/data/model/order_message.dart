import 'dart:io';

import 'package:equatable/equatable.dart';

/// One chat-style entry the user authored while creating an order — a typed
/// text line or a recorded voice note. Ordered by [position]; the list lives
/// on [OrderCreateState.messages].
sealed class OrderMessage extends Equatable {
  const OrderMessage({required this.position});

  final int position;
}

class OrderTextMessage extends OrderMessage {
  const OrderTextMessage({required super.position, required this.text});

  final String text;

  @override
  List<Object?> get props => [position, text];
}

class OrderAudioMessage extends OrderMessage {
  const OrderAudioMessage({
    required super.position,
    required this.path,
    required this.duration,
    required this.peaks,
  });

  /// Local file path on disk — uploaded as multipart at submit time.
  final String path;
  final Duration duration;
  final List<double> peaks;

  File get file => File(path);

  @override
  List<Object?> get props => [position, path, duration, peaks];
}

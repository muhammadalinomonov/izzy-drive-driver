part of 'order_create_bloc.dart';

@immutable
abstract class OrderCreateEvent extends Equatable {
  const OrderCreateEvent();
  @override
  List<Object?> get props => [];
}

class OrderCreateInitialized extends OrderCreateEvent {
  const OrderCreateInitialized({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
  final String address;
  final double latitude;
  final double longitude;
  @override
  List<Object?> get props => [address, latitude, longitude];
}

class QuestionsFetchRequested extends OrderCreateEvent {
  const QuestionsFetchRequested();
}

class ReviewRequested extends OrderCreateEvent {
  const ReviewRequested();
}

class ReviewDismissed extends OrderCreateEvent {
  const ReviewDismissed();
}

/// Appends a typed message to [OrderCreateState.messages].
class TextMessageAppended extends OrderCreateEvent {
  const TextMessageAppended(this.text);
  final String text;
  @override
  List<Object?> get props => [text];
}

/// Removes a message by its [position] (chronological index).
class MessageRemoved extends OrderCreateEvent {
  const MessageRemoved(this.position);
  final int position;
  @override
  List<Object?> get props => [position];
}

class AudioRecordingStarted extends OrderCreateEvent {
  const AudioRecordingStarted();
}

class AudioRecordingTicked extends OrderCreateEvent {
  const AudioRecordingTicked(this.elapsed);
  final Duration elapsed;
  @override
  List<Object?> get props => [elapsed];
}

/// Recorder finished — append a new [OrderAudioMessage] built from the
/// captured path + live peaks + elapsed duration.
class AudioRecordingStopped extends OrderCreateEvent {
  const AudioRecordingStopped(this.path);
  final String path;
  @override
  List<Object?> get props => [path];
}

class AudioRecordingCancelled extends OrderCreateEvent {
  const AudioRecordingCancelled();
}

class AudioPeakCaptured extends OrderCreateEvent {
  const AudioPeakCaptured(this.value);
  final double value; // 0..1
  @override
  List<Object?> get props => [value];
}

class PhotosAdded extends OrderCreateEvent {
  const PhotosAdded(this.files);
  final List<File> files;
  @override
  List<Object?> get props => [files];
}

class PhotoRemoved extends OrderCreateEvent {
  const PhotoRemoved(this.index);
  final int index;
  @override
  List<Object?> get props => [index];
}

class PriceChanged extends OrderCreateEvent {
  const PriceChanged(this.raw);
  final String raw; // digits-only
  @override
  List<Object?> get props => [raw];
}

class StepRequested extends OrderCreateEvent {
  const StepRequested(this.step);
  final OrderCreateStep step;
  @override
  List<Object?> get props => [step];
}

class OrderSubmitted extends OrderCreateEvent {
  const OrderSubmitted({required this.onSuccess, required this.onError});
  final void Function(int orderId) onSuccess;
  final void Function(String message) onError;
  @override
  List<Object?> get props => [];
}

class OrderCreateReset extends OrderCreateEvent {
  const OrderCreateReset();
}

part of 'order_create_bloc.dart';

enum OrderCreateStep {
  describing,       // typing or about to record
  recordingAudio,   // recorder running
  attachingMedia,   // browsing photos / preview
  enteringPrice,    // price input focused
  reviewing,        // final summary before submit
}

enum OrderCreateStatus { initial, submitting, success, failure }

@immutable
class OrderCreateState extends Equatable {
  const OrderCreateState({
    this.step = OrderCreateStep.describing,
    this.status = OrderCreateStatus.initial,
    this.description = '',
    this.audioPath,
    this.audioDuration = Duration.zero,
    this.isRecording = false,
    this.currentRecordingElapsed = Duration.zero,
    this.photos = const [],
    this.price = '',
    this.address = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.errorMessage = '',
    this.createdOrderId,
  });

  final OrderCreateStep step;
  final OrderCreateStatus status;

  final String description;

  final String? audioPath;
  final Duration audioDuration;
  final bool isRecording;
  final Duration currentRecordingElapsed;

  final List<File> photos;
  final String price;

  final String address;
  final double latitude;
  final double longitude;

  final String errorMessage;
  final int? createdOrderId;

  bool get hasContent =>
      description.trim().isNotEmpty || audioPath != null || photos.isNotEmpty;

  bool get canSubmit => hasContent && price.isNotEmpty;

  OrderCreateState copyWith({
    OrderCreateStep? step,
    OrderCreateStatus? status,
    String? description,
    String? audioPath,
    bool clearAudioPath = false,
    Duration? audioDuration,
    bool? isRecording,
    Duration? currentRecordingElapsed,
    List<File>? photos,
    String? price,
    String? address,
    double? latitude,
    double? longitude,
    String? errorMessage,
    int? createdOrderId,
  }) {
    return OrderCreateState(
      step: step ?? this.step,
      status: status ?? this.status,
      description: description ?? this.description,
      audioPath: clearAudioPath ? null : (audioPath ?? this.audioPath),
      audioDuration: audioDuration ?? this.audioDuration,
      isRecording: isRecording ?? this.isRecording,
      currentRecordingElapsed:
          currentRecordingElapsed ?? this.currentRecordingElapsed,
      photos: photos ?? this.photos,
      price: price ?? this.price,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      errorMessage: errorMessage ?? this.errorMessage,
      createdOrderId: createdOrderId ?? this.createdOrderId,
    );
  }

  @override
  List<Object?> get props => [
    step,
    status,
    description,
    audioPath,
    audioDuration,
    isRecording,
    currentRecordingElapsed,
    photos,
    price,
    address,
    latitude,
    longitude,
    errorMessage,
    createdOrderId,
  ];
}

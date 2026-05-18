part of 'order_create_bloc.dart';

enum OrderCreateStep {
  describing,       // typing or about to record
  recordingAudio,   // recorder running
  attachingMedia,   // browsing photos / preview
  enteringPrice,    // price input focused
  reviewing,        // final summary before submit
}

enum OrderCreateStatus { initial, submitting, success, failure }
enum QuestionsLoadStatus { initial, loading, success, failure }

@immutable
class OrderCreateState extends Equatable {
  const OrderCreateState({
    this.step = OrderCreateStep.describing,
    this.status = OrderCreateStatus.initial,
    this.questionsStatus = QuestionsLoadStatus.initial,
    this.questions = const [],
    this.description = '',
    this.audioPath,
    this.audioDuration = Duration.zero,
    this.audioPeaks = const [],
    this.isRecording = false,
    this.currentRecordingElapsed = Duration.zero,
    this.photos = const [],
    this.price = '',
    this.address = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.errorMessage = '',
    this.createdOrderId,
    this.showReview = false,
  });

  final OrderCreateStep step;
  final OrderCreateStatus status;
  final QuestionsLoadStatus questionsStatus;
  final List<QuestionTemplate> questions;

  final String description;

  final String? audioPath;
  final Duration audioDuration;
  // Normalized amplitude samples (0..1) captured while recording.
  // Sent to the backend so the mechanic app can render the same bars.
  final List<double> audioPeaks;
  final bool isRecording;
  final Duration currentRecordingElapsed;

  final List<File> photos;
  final String price;

  final String address;
  final double latitude;
  final double longitude;

  final String errorMessage;
  final int? createdOrderId;
  final bool showReview;

  bool get hasContent =>
      description.trim().isNotEmpty || audioPath != null || photos.isNotEmpty;

  bool get canSubmit => hasContent && price.isNotEmpty;

  /// True when the user has provided an answer for the given question type.
  bool hasAnswerFor(QuestionType type) {
    switch (type) {
      case QuestionType.textOrAudio:
        return description.trim().isNotEmpty || audioPath != null;
      case QuestionType.photos:
        return photos.isNotEmpty;
      case QuestionType.price:
        return price.isNotEmpty;
      case QuestionType.text:
        return description.trim().isNotEmpty;
      case QuestionType.unknown:
        return true;
    }
  }

  /// Index of the next unanswered question in [questions], or `questions.length`
  /// when all are answered.
  int get currentQuestionIndex {
    for (var i = 0; i < questions.length; i++) {
      if (!hasAnswerFor(questions[i].type)) return i;
    }
    return questions.length;
  }

  /// True when the user has answered every required question.
  bool get allQuestionsAnswered =>
      questions.isNotEmpty &&
      questions.every((q) => hasAnswerFor(q.type));

  OrderCreateState copyWith({
    OrderCreateStep? step,
    OrderCreateStatus? status,
    QuestionsLoadStatus? questionsStatus,
    List<QuestionTemplate>? questions,
    String? description,
    String? audioPath,
    bool clearAudioPath = false,
    Duration? audioDuration,
    List<double>? audioPeaks,
    bool? isRecording,
    Duration? currentRecordingElapsed,
    List<File>? photos,
    String? price,
    String? address,
    double? latitude,
    double? longitude,
    String? errorMessage,
    int? createdOrderId,
    bool? showReview,
  }) {
    return OrderCreateState(
      step: step ?? this.step,
      status: status ?? this.status,
      questionsStatus: questionsStatus ?? this.questionsStatus,
      questions: questions ?? this.questions,
      description: description ?? this.description,
      audioPath: clearAudioPath ? null : (audioPath ?? this.audioPath),
      audioDuration: audioDuration ?? this.audioDuration,
      audioPeaks: audioPeaks ?? this.audioPeaks,
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
      showReview: showReview ?? this.showReview,
    );
  }

  @override
  List<Object?> get props => [
    step,
    status,
    questionsStatus,
    questions,
    description,
    audioPath,
    audioDuration,
    audioPeaks,
    isRecording,
    currentRecordingElapsed,
    photos,
    price,
    address,
    latitude,
    longitude,
    errorMessage,
    createdOrderId,
    showReview,
  ];
}

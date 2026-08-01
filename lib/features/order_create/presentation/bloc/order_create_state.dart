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
    this.messages = const [],
    this.currentRecordingPeaks = const [],
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

  /// Committed chat-style entries authored so far. Either typed text or
  /// finished voice notes; rendered in position order both in the chat and
  /// on the wire (`messages` JSON sent to the backend).
  final List<OrderMessage> messages;

  /// Live amplitude buffer captured while the recorder is running. Becomes
  /// the [OrderAudioMessage.peaks] when recording stops; reset on the next
  /// recording start.
  final List<double> currentRecordingPeaks;
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

  /// All text messages joined into one paragraph — used for review summary
  /// display and as the legacy `text` field on the multipart submission.
  String get description => messages
      .whereType<OrderTextMessage>()
      .map((m) => m.text)
      .join('\n');

  bool get hasAudio => messages.any((m) => m is OrderAudioMessage);

  bool get hasContent => messages.isNotEmpty || photos.isNotEmpty;

  bool get canSubmit => hasContent && price.isNotEmpty;

  /// True when the user has provided an answer for the given question type.
  bool hasAnswerFor(QuestionType type) {
    switch (type) {
      case QuestionType.textOrAudio:
        return messages.isNotEmpty;
      case QuestionType.photos:
        return photos.isNotEmpty;
      case QuestionType.price:
        return price.isNotEmpty;
      case QuestionType.text:
        return messages.any((m) => m is OrderTextMessage);
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
    List<OrderMessage>? messages,
    List<double>? currentRecordingPeaks,
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
      messages: messages ?? this.messages,
      currentRecordingPeaks:
          currentRecordingPeaks ?? this.currentRecordingPeaks,
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
    messages,
    currentRecordingPeaks,
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

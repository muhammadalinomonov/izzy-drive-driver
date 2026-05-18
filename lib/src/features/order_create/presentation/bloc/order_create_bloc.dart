import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/src/features/order_create/data/model/order_create_request_model.dart';
import 'package:taxi_app/src/features/order_create/data/model/question_template_model.dart';
import 'package:taxi_app/src/features/order_create/domain/repo/order_create_repo.dart';

part 'order_create_event.dart';
part 'order_create_state.dart';

class OrderCreateBloc extends Bloc<OrderCreateEvent, OrderCreateState> {
  OrderCreateBloc({required this.repo}) : super(const OrderCreateState()) {
    on<OrderCreateInitialized>(_onInitialized);
    on<QuestionsFetchRequested>(_onQuestionsFetchRequested);
    on<DescriptionChanged>(_onDescriptionChanged);
    on<AudioRecordingStarted>(_onAudioRecordingStarted);
    on<AudioRecordingTicked>(_onAudioRecordingTicked);
    on<AudioRecordingStopped>(_onAudioRecordingStopped);
    on<AudioRecordingCancelled>(_onAudioRecordingCancelled);
    on<AudioPeakCaptured>(_onAudioPeakCaptured);
    on<AudioCleared>(_onAudioCleared);
    on<PhotosAdded>(_onPhotosAdded);
    on<PhotoRemoved>(_onPhotoRemoved);
    on<PriceChanged>(_onPriceChanged);
    on<StepRequested>(_onStepRequested);
    on<ReviewRequested>(_onReviewRequested);
    on<ReviewDismissed>(_onReviewDismissed);
    on<OrderSubmitted>(_onOrderSubmitted);
    on<OrderCreateReset>(_onReset);
  }

  final OrderCreateRepo repo;

  void _onInitialized(OrderCreateInitialized event, Emitter<OrderCreateState> emit) {
    emit(state.copyWith(
      address: event.address,
      latitude: event.latitude,
      longitude: event.longitude,
    ));
  }

  Future<void> _onQuestionsFetchRequested(
    QuestionsFetchRequested event,
    Emitter<OrderCreateState> emit,
  ) async {
    if (state.questionsStatus == QuestionsLoadStatus.loading) return;
    emit(state.copyWith(questionsStatus: QuestionsLoadStatus.loading));
    final response = await repo.fetchQuestions();
    if (response.errorText.isEmpty && (response.data?.isNotEmpty ?? false)) {
      emit(state.copyWith(
        questionsStatus: QuestionsLoadStatus.success,
        questions: response.data!,
      ));
    } else {
      // Fallback so the user can still create an order if the API fails.
      emit(state.copyWith(
        questionsStatus: QuestionsLoadStatus.failure,
        questions: _fallbackQuestions,
        errorMessage: response.errorText,
      ));
    }
  }

  void _onReviewRequested(ReviewRequested event, Emitter<OrderCreateState> emit) {
    if (!state.canSubmit) return;
    emit(state.copyWith(showReview: true));
  }

  void _onReviewDismissed(ReviewDismissed event, Emitter<OrderCreateState> emit) {
    emit(state.copyWith(showReview: false));
  }

  void _onDescriptionChanged(DescriptionChanged event, Emitter<OrderCreateState> emit) {
    emit(state.copyWith(description: event.value));
  }

  void _onAudioRecordingStarted(
    AudioRecordingStarted event,
    Emitter<OrderCreateState> emit,
  ) {
    emit(state.copyWith(
      step: OrderCreateStep.recordingAudio,
      isRecording: true,
      currentRecordingElapsed: Duration.zero,
      audioPeaks: const [],
    ));
  }

  void _onAudioRecordingTicked(
    AudioRecordingTicked event,
    Emitter<OrderCreateState> emit,
  ) {
    emit(state.copyWith(currentRecordingElapsed: event.elapsed));
  }

  void _onAudioRecordingStopped(
    AudioRecordingStopped event,
    Emitter<OrderCreateState> emit,
  ) {
    emit(state.copyWith(
      step: OrderCreateStep.describing,
      isRecording: false,
      audioPath: event.path,
      audioDuration: state.currentRecordingElapsed,
      currentRecordingElapsed: Duration.zero,
    ));
  }

  void _onAudioRecordingCancelled(
    AudioRecordingCancelled event,
    Emitter<OrderCreateState> emit,
  ) {
    emit(state.copyWith(
      step: OrderCreateStep.describing,
      isRecording: false,
      currentRecordingElapsed: Duration.zero,
      audioPeaks: const [],
    ));
  }

  void _onAudioPeakCaptured(
    AudioPeakCaptured event,
    Emitter<OrderCreateState> emit,
  ) {
    // Cap the buffer — backend trims to 256 anyway and longer lists hurt
    // bubble-render perf. At a 200ms sample rate this caps recordings at
    // ~51 seconds before we start dropping the head; for longer recordings
    // we still capture the *recent* envelope.
    const max = 256;
    final next = state.audioPeaks.length >= max
        ? <double>[...state.audioPeaks.sublist(1), event.value]
        : <double>[...state.audioPeaks, event.value];
    emit(state.copyWith(audioPeaks: next));
  }

  void _onAudioCleared(AudioCleared event, Emitter<OrderCreateState> emit) {
    emit(state.copyWith(
      clearAudioPath: true,
      audioDuration: Duration.zero,
      audioPeaks: const [],
    ));
  }

  void _onPhotosAdded(PhotosAdded event, Emitter<OrderCreateState> emit) {
    final combined = [...state.photos, ...event.files];
    final capped = combined.length > 5 ? combined.sublist(0, 5) : combined;
    emit(state.copyWith(photos: capped));
  }

  void _onPhotoRemoved(PhotoRemoved event, Emitter<OrderCreateState> emit) {
    if (event.index < 0 || event.index >= state.photos.length) return;
    final updated = [...state.photos]..removeAt(event.index);
    emit(state.copyWith(photos: updated));
  }

  void _onPriceChanged(PriceChanged event, Emitter<OrderCreateState> emit) {
    final digits = event.raw.replaceAll(RegExp(r'\D'), '');
    emit(state.copyWith(price: digits));
  }

  void _onStepRequested(StepRequested event, Emitter<OrderCreateState> emit) {
    emit(state.copyWith(step: event.step));
  }

  Future<void> _onOrderSubmitted(
    OrderSubmitted event,
    Emitter<OrderCreateState> emit,
  ) async {
    if (!state.canSubmit) {
      emit(state.copyWith(
        status: OrderCreateStatus.failure,
        errorMessage: 'Please enter the issue and price',
      ));
      event.onError('Please enter the issue and price');
      return;
    }
    emit(state.copyWith(status: OrderCreateStatus.submitting, errorMessage: ''));

    final request = OrderCreateRequestModel(
      text: state.description.trim(),
      voiceFile: state.audioPath != null ? File(state.audioPath!) : null,
      voicePeaks: state.audioPeaks,
      photos: state.photos,
      price: state.price,
      latitude: state.latitude,
      longitude: state.longitude,
    );

    final response = await repo.createOrder(request);
    if (response.errorText.isEmpty) {
      final orderId = response.data?.data?.orderId ?? -1;
      emit(state.copyWith(
        status: OrderCreateStatus.success,
        createdOrderId: orderId,
      ));
      event.onSuccess(orderId);
    } else {
      emit(state.copyWith(
        status: OrderCreateStatus.failure,
        errorMessage: response.errorText,
      ));
      event.onError(response.errorText);
    }
  }

  void _onReset(OrderCreateReset event, Emitter<OrderCreateState> emit) {
    emit(const OrderCreateState());
  }
}

// Used when /accounts/questions-templates/ is unreachable so the user can
// still complete the flow. Mirrors the 3 default backend rows.
const List<QuestionTemplate> _fallbackQuestions = [
  QuestionTemplate(
    id: -1,
    key: 'question_1',
    title: 'Describe the problem',
    body: 'Describe the issue or explain it with a voice message.',
    type: QuestionType.textOrAudio,
    order: 1,
    isActive: true,
  ),
  QuestionTemplate(
    id: -2,
    key: 'question_2',
    title: 'Add a photo',
    body: 'Upload a photo or video of the problem. You can also add a voice message or text for any extra details.',
    type: QuestionType.photos,
    order: 2,
    isActive: true,
  ),
  QuestionTemplate(
    id: -3,
    key: 'question_3',
    title: 'Price',
    body: 'How much do you want to pay for this work?',
    type: QuestionType.price,
    order: 3,
    isActive: true,
  ),
];

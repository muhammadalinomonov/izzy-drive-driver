import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/src/features/order_create/data/model/order_create_request_model.dart';
import 'package:taxi_app/src/features/order_create/domain/repo/order_create_repo.dart';

part 'order_create_event.dart';
part 'order_create_state.dart';

class OrderCreateBloc extends Bloc<OrderCreateEvent, OrderCreateState> {
  OrderCreateBloc({required this.repo}) : super(const OrderCreateState()) {
    on<OrderCreateInitialized>(_onInitialized);
    on<DescriptionChanged>(_onDescriptionChanged);
    on<AudioRecordingStarted>(_onAudioRecordingStarted);
    on<AudioRecordingTicked>(_onAudioRecordingTicked);
    on<AudioRecordingStopped>(_onAudioRecordingStopped);
    on<AudioRecordingCancelled>(_onAudioRecordingCancelled);
    on<AudioCleared>(_onAudioCleared);
    on<PhotosAdded>(_onPhotosAdded);
    on<PhotoRemoved>(_onPhotoRemoved);
    on<PriceChanged>(_onPriceChanged);
    on<StepRequested>(_onStepRequested);
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
    ));
  }

  void _onAudioCleared(AudioCleared event, Emitter<OrderCreateState> emit) {
    emit(state.copyWith(
      clearAudioPath: true,
      audioDuration: Duration.zero,
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
        errorMessage: 'Iltimos, muammo va narxni kiriting',
      ));
      event.onError('Iltimos, muammo va narxni kiriting');
      return;
    }
    emit(state.copyWith(status: OrderCreateStatus.submitting, errorMessage: ''));

    final request = OrderCreateRequestModel(
      text: state.description.trim(),
      voiceFile: state.audioPath != null ? File(state.audioPath!) : null,
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

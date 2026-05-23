import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:taxi_app/src/features/profile/data/model/profile_model.dart';
import 'package:taxi_app/src/features/profile/domain/entities/output_entity.dart';

import '../../domain/repository/profile_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;

  ProfileBloc(this.repository) : super(ProfileState(status: ProfileStatus.initial)) {
    on<LoadProfile>((event, emit) async {
      emit(state.copyWith(status: ProfileStatus.loading));
      final result = await repository.getProfile();
      if (result.errorText.isEmpty) {
        print((result.data as ProfileModel));
        emit(state.copyWith(profile: result.data, status: ProfileStatus.loaded));
      } else {
        emit(state.copyWith(status: ProfileStatus.error, message: result.errorText));
      }
    });

    on<GetOutputsEvent>(_onGetOutputsEvent);
    on<CreateOutputEvent>(_onCreateOutputEvent);
    on<UpdatePasswordEvent>(_onUpdatePasswordEvent);
    on<UploadAvatarEvent>(_onUploadAvatarEvent);
  }

  Future<void> _onUploadAvatarEvent(
    UploadAvatarEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(uploadAvatarStatus: FormzSubmissionStatus.inProgress));
    final result = await repository.uploadAvatar(event.file);
    if (result.errorText.isEmpty) {
      final newUrl = result.data ?? '';
      final oldUrl = state.profile?.photo ?? '';
      // Backend yangi rasmni eski URL'ga overwrite qilishi mumkin -
      // shu sababli Flutter'ning image cache'ida eski rasm qoladi va
      // Image.network qayta render bo'lganda eski rasmni ko'rsatadi.
      // Cache'dan eski (va xavfsizlik uchun yangi) URL entry'larini
      // o'chiramiz - keyingi render fresh fetch qiladi.
      if (oldUrl.isNotEmpty) {
        await NetworkImage(oldUrl).evict();
      }
      if (newUrl.isNotEmpty && newUrl != oldUrl) {
        await NetworkImage(newUrl).evict();
      }
      // Patch the profile in-place with the new avatar URL - avoids
      // an extra GET /drivers/get-me/ roundtrip.
      final updated = state.profile?.copyWith(photo: newUrl);
      emit(
        state.copyWith(
          profile: updated,
          uploadAvatarStatus: FormzSubmissionStatus.success,
        ),
      );
      event.onSuccess?.call();
    } else {
      emit(
        state.copyWith(
          uploadAvatarStatus: FormzSubmissionStatus.failure,
          message: result.errorText,
        ),
      );
      event.onError?.call(result.errorText);
    }
  }

  Future<void> _onGetOutputsEvent(GetOutputsEvent event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(outputsStatus: FormzSubmissionStatus.inProgress));
    final result = await repository.getAllOutputs();
    result.either(
      (failure) {
        emit(state.copyWith(outputsStatus: FormzSubmissionStatus.failure, message: failure.errorMessage));
      },
      (pagination) {
        emit(
          state.copyWith(
            outputsStatus: FormzSubmissionStatus.success,
            outputs: pagination.data,
            totalAmount: pagination.totalSum.toString(),
          ),
        );
      },
    );
  }

  Future<void> _onCreateOutputEvent(CreateOutputEvent event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(createOutputStatus: FormzSubmissionStatus.inProgress));
    final data = {'title': event.title, 'amount': event.amount, 'date': event.date};
    final result = await repository.create(data);
    result.either(
      (failure) {
        emit(state.copyWith(createOutputStatus: FormzSubmissionStatus.failure, message: failure.errorMessage));
      },
      (_) {
        emit(state.copyWith(createOutputStatus: FormzSubmissionStatus.success));
        add(GetOutputsEvent());
      },
    );
  }

  Future<void> _onUpdatePasswordEvent(UpdatePasswordEvent event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(updatePasswordStatus: FormzSubmissionStatus.inProgress));

    final data = {'old_password': event.oldPassword, 'new_password': event.newPassword};
    final result = await repository.updatePassword(data);

    result.either(
      (failure) {
        event.onError.call(failure.errorMessage ?? '');
        emit(state.copyWith(updatePasswordStatus: FormzSubmissionStatus.failure, message: failure.errorMessage));
      },
      (_) {
        event.onSuccess.call();
        emit(state.copyWith(updatePasswordStatus: FormzSubmissionStatus.success));
      },
    );
  }
}

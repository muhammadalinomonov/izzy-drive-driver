import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mechanic/core/usecases/use_case.dart';
import 'package:mechanic/core/utils/service_locator.dart';
import 'package:mechanic/features/auth/domain/entities/user_entity.dart';
import 'package:mechanic/features/auth/domain/usecases/get_user_usecase.dart';
import 'package:mechanic/features/profile/domain/entities/static_entity.dart';
import 'package:mechanic/features/profile/domain/usecases/get_user_statistics_usecase.dart';
import 'package:mechanic/features/profile/domain/usecases/update_current_location_usecase.dart';
import 'package:mechanic/features/profile/domain/usecases/update_status_usecase.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetUserDataUseCase _getUserDataUseCase = GetUserDataUseCase(repository: serviceLocator.call());
  final UpdateStatusUseCase _updateStatusUseCase = UpdateStatusUseCase(repository: serviceLocator.call());
  final UpdateCurrentLocationUseCase _updateCurrentLocationUseCase =
      UpdateCurrentLocationUseCase(repository: serviceLocator.call());
  final GetUserStatisticsUseCase _getUserStatisticsUseCase =
      GetUserStatisticsUseCase(repository: serviceLocator.call());

  ProfileBloc() : super(ProfileState()) {
    on<GetProfileEvent>(_onGetProfileEvent);
    on<UpdateStatusEvent>(_onUpdateStatus);
    on<_UpdateCurrentLocationEvent>(_onUpdateCurrentLocationEvent);
    on<_ListenUserLocationEvent>(_onListenUserLocationEvent);
    on<_CancelListenUserLocationEvent>(_onCancelListenUserLocationEvent);
    on<GetUserStatisticsEvent>(_onGetUserStatisticsEvent);
    on<SelectStatistic>(_onSelectStatistic);
  }

  Future<void> _onGetProfileEvent(GetProfileEvent event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(getProfileStatus: FormzSubmissionStatus.inProgress));
    final result = await _getUserDataUseCase(NoParams());
    result.either(
        (failure) =>
            emit(state.copyWith(getProfileStatus: FormzSubmissionStatus.failure, errorMessage: failure.errorMessage)),
        (user) {
      emit(state.copyWith(getProfileStatus: FormzSubmissionStatus.success, user: user, status: user.status));

      if (user.status == 'online') {
        add(_ListenUserLocationEvent());
      } else {
        add(_CancelListenUserLocationEvent());
      }
    });
  }

  Future<void> _onUpdateStatus(UpdateStatusEvent event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(updateStatusStatus: FormzSubmissionStatus.inProgress));
    final result = await _updateStatusUseCase(event.isOnline);
    result.either(
      (failure) => emit(
          state.copyWith(updateStatusStatus: FormzSubmissionStatus.failure, errorMessage: failure.errorMessage ?? '')),
      (_) async {
        emit(state.copyWith(
          updateStatusStatus: FormzSubmissionStatus.success,
          status: event.isOnline ? 'online' : 'offline',
        ));
        if (event.isOnline) {
          add(_ListenUserLocationEvent());
        } else {
          add(_CancelListenUserLocationEvent());
        }
      },
    );
  }

  Future<void> _onListenUserLocationEvent(_ListenUserLocationEvent event, Emitter<ProfileState> emit) async {
    // _timer = Timer.periodic(Duration(seconds: 5000), (timer) async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      Geolocator.getPositionStream(
          locationSettings: LocationSettings(
        distanceFilter: 10,
        timeLimit: Duration(seconds: 5),
      )).listen((Position position) {
        add(_UpdateCurrentLocationEvent(latitude: position.latitude, longitude: position.longitude));
      });
    } else {
      await Geolocator.openAppSettings();
    }
    // });
  }

  Future<void> _onCancelListenUserLocationEvent(
      _CancelListenUserLocationEvent event, Emitter<ProfileState> emit) async {
    // _timer?.cancel();
    // _timer = null;
    emit(state.copyWith(updateCurrentLocationStatus: FormzSubmissionStatus.initial));
  }

  Future<void> _onUpdateCurrentLocationEvent(_UpdateCurrentLocationEvent event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(updateCurrentLocationStatus: FormzSubmissionStatus.inProgress));
    final result = await _updateCurrentLocationUseCase((event.latitude, event.longitude));
    result.either(
      (failure) => emit(state.copyWith(
          updateCurrentLocationStatus: FormzSubmissionStatus.failure, errorMessage: failure.errorMessage ?? '')),
      (_) {
        emit(state.copyWith(updateCurrentLocationStatus: FormzSubmissionStatus.success));
      },
    );
  }

  Future<void> _onGetUserStatisticsEvent(GetUserStatisticsEvent event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(getUserStatisticsStatus: FormzSubmissionStatus.inProgress));
    final result = await _getUserStatisticsUseCase((filter: event.filter, period: event.period));
    result.either(
      (failure) => emit(state.copyWith(
          getUserStatisticsStatus: FormzSubmissionStatus.failure, errorMessage: failure.errorMessage ?? '')),
      (statistics) {
        emit(state.copyWith(
          getUserStatisticsStatus: FormzSubmissionStatus.success,
          statistics: statistics,
          selectedFilter: event.filter,
          selectedPeriod: event.period,
          selectedStatistic: statistics.isNotEmpty ? statistics.last : StatisticEntity(),
        ));
      },
    );
  }

  void _onSelectStatistic(SelectStatistic event, Emitter<ProfileState> emit) {
    emit(state.copyWith(selectedStatistic: event.statistic));
  }
}

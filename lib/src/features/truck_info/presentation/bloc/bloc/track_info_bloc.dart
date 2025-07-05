import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/animation.dart';
import 'package:taxi_app/src/features/truck_info/domain/model/track_model.dart';
import 'package:taxi_app/src/features/truck_info/domain/repo/driver_info_repo.dart';

part 'track_info_event.dart';
part 'track_info_state.dart';

class TrackInfoBloc extends Bloc<TrackInfoEvent, TrackInfoState> {
  final DriverInfoRepo driverInfoRepo;

  TrackInfoBloc({required this.driverInfoRepo})
    : super(TrackInfoState(status: TrackInfoStatus.initial)) {
    on<GetTrackMarskEvent>((event, emit) async {
      emit(TrackInfoState(status: TrackInfoStatus.loading));
      final result = await driverInfoRepo.getTrackMarks();
      if (result.errorText.isEmpty) {
        print('TrackInfoBloc ${(result.data as TruckMarkResponse).data}');
        emit(
          TrackInfoState(
            status: TrackInfoStatus.success,
            truckMarkResponse: result.data as TruckMarkResponse,
          ),
        );
      } else {
        emit(
          TrackInfoState(
            status: TrackInfoStatus.error,
            errorMessage: result.errorText,
          ),
        );
      }
    });

    on<GetTrackModelsEvent>((event, emit) async {
      emit(state.copyWith(status: TrackInfoStatus.loading));
      final result = await driverInfoRepo.getTrackModels(event.id);
      if (result.errorText.isEmpty) {
        emit(
          state.copyWith(
            status: TrackInfoStatus.success,
            truckModelResponse: result.data as TruckModelResponse,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: TrackInfoStatus.error,
            errorMessage: result.errorText,
          ),
        );
      }
    });
  }
}

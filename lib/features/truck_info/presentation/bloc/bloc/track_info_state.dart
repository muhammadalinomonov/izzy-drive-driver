part of 'track_info_bloc.dart';

enum TrackInfoStatus { initial, loading, error, success }

class TrackInfoState extends Equatable {
  final TrackInfoStatus marksStatus;
  final TrackInfoStatus modelsStatus;
  final TruckMarkResponse? truckMarkResponse;
  final TruckModelResponse? truckModelResponse;
  final String? errorMessage;

  const TrackInfoState({
    this.marksStatus = TrackInfoStatus.initial,
    this.modelsStatus = TrackInfoStatus.initial,
    this.truckMarkResponse,
    this.truckModelResponse,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
    marksStatus,
    modelsStatus,
    truckMarkResponse,
    truckModelResponse,
    errorMessage,
  ];

  TrackInfoState copyWith({
    TrackInfoStatus? marksStatus,
    TrackInfoStatus? modelsStatus,
    TruckMarkResponse? truckMarkResponse,
    TruckModelResponse? truckModelResponse,
    String? errorMessage,
  }) {
    return TrackInfoState(
      marksStatus: marksStatus ?? this.marksStatus,
      modelsStatus: modelsStatus ?? this.modelsStatus,
      truckMarkResponse: truckMarkResponse ?? this.truckMarkResponse,
      truckModelResponse: truckModelResponse ?? this.truckModelResponse,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
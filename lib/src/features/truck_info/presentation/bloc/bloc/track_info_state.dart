part of 'track_info_bloc.dart';

enum TrackInfoStatus { initial, loading, error, success }

class TrackInfoState extends Equatable {
  final TrackInfoStatus status;
  final TruckMarkResponse? truckMarkResponse;
  final TruckModelResponse? truckModelResponse;
  final String? errorMessage;
  const TrackInfoState({
    required this.status,
    this.truckMarkResponse,
    this.truckModelResponse,
    this.errorMessage,
  });

  @override
  List<Object> get props => [
    status,
    TrackInfoStatus.error,
    TrackInfoStatus.initial,
    TrackInfoStatus.success,
    errorMessage ?? ''
  ];
}

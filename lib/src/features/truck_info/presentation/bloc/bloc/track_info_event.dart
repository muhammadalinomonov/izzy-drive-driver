part of 'track_info_bloc.dart';

sealed class TrackInfoEvent extends Equatable {
  const TrackInfoEvent();

  @override
  List<Object> get props => [];
}

class GetTrackMarskEvent extends TrackInfoEvent {
  final VoidCallback onError;

  const GetTrackMarskEvent({required this.onError});
}

class GetTrackModelsEvent extends TrackInfoEvent {
  final String id;

  const GetTrackModelsEvent({required this.id});

  @override
  List<Object> get props => [id];
}

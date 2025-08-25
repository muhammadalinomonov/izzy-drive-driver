part of 'profile_bloc.dart';

@immutable
class ProfileEvent {}

class UpdateStatusEvent extends ProfileEvent {
  final bool isOnline;

  UpdateStatusEvent({required this.isOnline});
}

class GetProfileEvent extends ProfileEvent {}

class _UpdateCurrentLocationEvent extends ProfileEvent {
  final double latitude;
  final double longitude;

  _UpdateCurrentLocationEvent({required this.latitude, required this.longitude});
}

class _ListenUserLocationEvent extends ProfileEvent {}

class _CancelListenUserLocationEvent extends ProfileEvent {}

class GetUserStatisticsEvent extends ProfileEvent {
  final String filter;
  final String period;

  GetUserStatisticsEvent({required this.filter, required this.period});
}

class SelectStatisticFilterEvent extends ProfileEvent {
  final String filter;

  SelectStatisticFilterEvent({required this.filter});
}

class SelectStatistic extends ProfileEvent {
  final StatisticEntity statistic;

  SelectStatistic({required this.statistic});
}

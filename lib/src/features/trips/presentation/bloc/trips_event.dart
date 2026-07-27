part of 'trips_bloc.dart';

sealed class TripsEvent extends Equatable {
  const TripsEvent();

  @override
  List<Object?> get props => [];
}

class TripsLoaded extends TripsEvent {
  const TripsLoaded();
}

class TripsRefreshed extends TripsEvent {
  const TripsRefreshed();
}

class TripsLoadMore extends TripsEvent {
  const TripsLoadMore();
}

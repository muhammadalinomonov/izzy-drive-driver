part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

class GetBannersEvent extends HomeEvent {
  /// When true, skip emitting `loading` if banners are already loaded —
  /// used by pull-to-refresh so the carousel doesn't collapse into a shimmer
  /// while the user is looking at it.
  final bool silent;

  const GetBannersEvent({this.silent = false});

  @override
  List<Object> get props => [silent];
}

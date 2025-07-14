part of 'home_bloc.dart';

class HomeState extends Equatable {
  final HomeStatus status;
  final String errorMessage;
  final List<Map> banners;

  const HomeState({
    required this.status,
    this.errorMessage = '',
    this.banners = const [],
  });

  HomeState copyWith({
    HomeStatus? status,
    String? errorMessage,
    List<Map>? banners,
  }) {
    return HomeState(
      status: status ?? this.status,
      banners: banners ?? this.banners,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object> get props => [status, errorMessage, banners];
}

enum HomeStatus { initial, loading, success, error }

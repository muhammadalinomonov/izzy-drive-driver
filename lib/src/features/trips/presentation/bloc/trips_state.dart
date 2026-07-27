part of 'trips_bloc.dart';

enum TripsListStatus { initial, loading, success, failure }

class TripsState extends Equatable {
  final TripsListStatus listStatus;
  final TripsListStatus loadMoreStatus;
  final List<TripModel> items;
  final int page;
  final int lastPage;
  final int total;
  final String errorMessage;

  /// Toll-API error code (e.g. `DRIVER_SUSPENDED`, `TOLL_SESSION_MISSING`).
  /// Lets the error view special-case a missing toll account without string
  /// matching on the message.
  final String errorCode;

  const TripsState({
    this.listStatus = TripsListStatus.initial,
    this.loadMoreStatus = TripsListStatus.initial,
    this.items = const [],
    this.page = 1,
    this.lastPage = 1,
    this.total = 0,
    this.errorMessage = '',
    this.errorCode = '',
  });

  bool get hasMore => page < lastPage;

  TripsState copyWith({
    TripsListStatus? listStatus,
    TripsListStatus? loadMoreStatus,
    List<TripModel>? items,
    int? page,
    int? lastPage,
    int? total,
    String? errorMessage,
    String? errorCode,
  }) {
    return TripsState(
      listStatus: listStatus ?? this.listStatus,
      loadMoreStatus: loadMoreStatus ?? this.loadMoreStatus,
      items: items ?? this.items,
      page: page ?? this.page,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      errorMessage: errorMessage ?? this.errorMessage,
      errorCode: errorCode ?? this.errorCode,
    );
  }

  @override
  List<Object?> get props => [
        listStatus,
        loadMoreStatus,
        items,
        page,
        lastPage,
        total,
        errorMessage,
        errorCode,
      ];
}

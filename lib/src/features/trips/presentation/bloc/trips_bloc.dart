import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/src/features/trips/data/model/navigation_session_model.dart';
import 'package:taxi_app/src/features/trips/data/model/trip_model.dart';
import 'package:taxi_app/src/features/trips/domain/repo/trips_repo.dart';

part 'trips_event.dart';
part 'trips_state.dart';

class TripsBloc extends Bloc<TripsEvent, TripsState> {
  final TripsRepo repo;

  static const int _perPage = 20;

  TripsBloc({required this.repo}) : super(const TripsState()) {
    on<TripsLoaded>(_onLoad);
    on<TripsRefreshed>(_onRefresh);
    on<TripsLoadMore>(_onLoadMore);
    on<TripsActiveSessionChecked>(_onActiveSessionChecked);
  }

  /// Resolves whether a trip is still running, for the Continue Route card.
  ///
  /// Failures are swallowed on purpose: this is a secondary affordance beside
  /// the trip history, and a dead network shouldn't push an error banner over
  /// a list that loaded fine. The card simply stays hidden.
  Future<void> _onActiveSessionChecked(
    TripsActiveSessionChecked event,
    Emitter<TripsState> emit,
  ) async {
    final response = await repo.getCurrentNavigationSession();
    if (response.errorText.isNotEmpty) return;
    final session = response.data;
    emit(state.copyWith(
      activeSession: session != null && session.isActive ? session : null,
    ));
  }

  Future<void> _onLoad(TripsLoaded event, Emitter<TripsState> emit) async {
    if (state.listStatus == TripsListStatus.loading) return;
    emit(state.copyWith(listStatus: TripsListStatus.loading, errorMessage: ''));
    final response = await repo.fetchPage(page: 1, perPage: _perPage);
    if (response.errorText.isEmpty && response.data != null) {
      final page = response.data!;
      emit(state.copyWith(
        listStatus: TripsListStatus.success,
        items: page.items,
        page: page.page,
        lastPage: page.lastPage,
        total: page.total,
        errorMessage: '',
        errorCode: '',
      ));
    } else {
      emit(state.copyWith(
        listStatus: TripsListStatus.failure,
        errorMessage: response.errorText,
        errorCode: response.errorCode ?? '',
      ));
    }
  }

  /// Pull-to-refresh: the RefreshIndicator spinner is the visible progress
  /// affordance, so the current list stays on screen rather than collapsing
  /// into the shimmer underneath it.
  Future<void> _onRefresh(TripsRefreshed event, Emitter<TripsState> emit) async {
    final response = await repo.fetchPage(page: 1, perPage: _perPage);
    if (response.errorText.isEmpty && response.data != null) {
      final page = response.data!;
      emit(state.copyWith(
        listStatus: TripsListStatus.success,
        items: page.items,
        page: page.page,
        lastPage: page.lastPage,
        total: page.total,
        errorMessage: '',
        errorCode: '',
      ));
    } else {
      // Keep whatever is already listed; a failed refresh shouldn't blank the
      // screen. If the list was empty the error view takes over as usual.
      emit(state.copyWith(
        listStatus: state.items.isEmpty
            ? TripsListStatus.failure
            : state.listStatus,
        errorMessage: response.errorText,
        errorCode: response.errorCode ?? '',
      ));
    }
  }

  Future<void> _onLoadMore(TripsLoadMore event, Emitter<TripsState> emit) async {
    if (state.loadMoreStatus == TripsListStatus.loading) return;
    if (!state.hasMore) return;
    emit(state.copyWith(loadMoreStatus: TripsListStatus.loading));
    final nextPage = state.page + 1;
    final response = await repo.fetchPage(page: nextPage, perPage: _perPage);
    if (response.errorText.isEmpty && response.data != null) {
      final page = response.data!;
      emit(state.copyWith(
        loadMoreStatus: TripsListStatus.success,
        items: [...state.items, ...page.items],
        page: page.page,
        lastPage: page.lastPage,
        total: page.total,
      ));
    } else {
      emit(state.copyWith(
        loadMoreStatus: TripsListStatus.failure,
        errorMessage: response.errorText,
        errorCode: response.errorCode ?? '',
      ));
    }
  }
}

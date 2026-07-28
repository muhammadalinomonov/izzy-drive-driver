import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/src/core/location_service.dart';
import 'package:taxi_app/src/features/trips/data/model/navigation_session_model.dart';
import 'package:taxi_app/src/features/trips/data/model/trip_model.dart';
import 'package:taxi_app/src/features/trips/domain/repo/trips_repo.dart';

part 'route_overview_event.dart';
part 'route_overview_state.dart';

/// Backs the route overview screen (docs/ui/8.png): lets the driver switch
/// between the alternatives priced by `POST /toll-routes` and, on Start,
/// opens (or resumes) a navigation session for the chosen one.
class RouteOverviewBloc extends Bloc<RouteOverviewEvent, RouteOverviewState> {
  final TripsRepo repo;
  final LocationService locationService;

  RouteOverviewBloc({
    required TripModel trip,
    required this.repo,
    required this.locationService,
  }) : super(RouteOverviewState(
          trip: trip,
          selectedAlternativeId: trip.recommendedAlternativeId,
        )) {
    on<RouteOverviewAlternativeSelected>(_onAlternativeSelected);
    on<RouteOverviewStartPressed>(_onStartPressed);
  }

  void _onAlternativeSelected(
    RouteOverviewAlternativeSelected event,
    Emitter<RouteOverviewState> emit,
  ) {
    if (event.alternativeId == state.selectedAlternativeId) return;
    emit(state.copyWith(selectedAlternativeId: event.alternativeId));
  }

  Future<void> _onStartPressed(
    RouteOverviewStartPressed event,
    Emitter<RouteOverviewState> emit,
  ) async {
    emit(state.copyWith(startStatus: RouteOverviewStartStatus.loading));

    // Best-effort fresh fix for `current_location` - the session starts fine
    // without one (the API falls back to the route's origin), so a GPS miss
    // here must not block Start.
    final position = await locationService.getCurrentLocation();

    final response = await repo.createNavigationSession(
      routeRequestId: state.trip.id,
      routeAlternativeId: state.selectedAlternativeId,
      currentLocation: position == null
          ? null
          : TripCoordinate(lat: position.latitude, lng: position.longitude),
    );

    if (response.errorText.isEmpty && response.data != null) {
      emit(state.copyWith(
        startStatus: RouteOverviewStartStatus.idle,
        session: response.data,
        startTick: state.startTick + 1,
      ));
    } else {
      emit(state.copyWith(
        startStatus: RouteOverviewStartStatus.failure,
        startError: response.errorText,
      ));
    }
  }
}

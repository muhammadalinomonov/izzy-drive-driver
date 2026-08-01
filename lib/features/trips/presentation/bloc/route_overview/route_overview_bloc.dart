import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/core/location_service.dart';
import 'package:taxi_app/features/trips/data/model/navigation_session_model.dart';
import 'package:taxi_app/features/trips/data/model/place_model.dart';
import 'package:taxi_app/features/trips/data/model/trip_model.dart';
import 'package:taxi_app/features/trips/domain/repo/trips_repo.dart';

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
    required PlaceModel? origin,
    required PlaceModel? destination,
    required this.repo,
    required this.locationService,
  }) : super(RouteOverviewState(
          trip: trip,
          selectedAlternativeId: trip.recommendedAlternativeId,
          origin: origin,
          destination: destination,
          // Opened from the history list: only the list model is known, whose
          // `toll_markers` may be empty (docs/mobile-api.md §4.1) and whose
          // endpoints have no labels. The page opens straight into its loading
          // state and RouteOverviewStarted fills the gap.
          loadStatus: origin == null || destination == null
              ? RouteOverviewLoadStatus.loading
              : RouteOverviewLoadStatus.idle,
        )) {
    on<RouteOverviewStarted>(_onStarted);
    on<RouteOverviewAlternativeSelected>(_onAlternativeSelected);
    on<RouteOverviewStartPressed>(_onStartPressed);
  }

  Future<void> _onStarted(
    RouteOverviewStarted event,
    Emitter<RouteOverviewState> emit,
  ) async {
    // The planner flow already carries the freshly calculated route and both
    // picked places - nothing to fetch.
    if (state.isReady) return;

    emit(state.copyWith(
      loadStatus: RouteOverviewLoadStatus.loading,
      loadError: '',
    ));

    final response = await repo.fetchById(state.trip.id);
    if (response.errorText.isNotEmpty || response.data == null) {
      emit(state.copyWith(
        loadStatus: RouteOverviewLoadStatus.failure,
        loadError: response.errorText,
      ));
      return;
    }

    final detail = response.data!;
    final places = await Future.wait([
      _placeFor(detail.origin, event.originFallbackLabel),
      _placeFor(detail.destination, event.destinationFallbackLabel),
    ]);

    emit(state.copyWith(
      trip: detail,
      selectedAlternativeId: detail.recommendedAlternativeId,
      origin: places[0],
      destination: places[1],
      loadStatus: RouteOverviewLoadStatus.idle,
      loadError: '',
    ));
  }

  /// The toll-route payload only carries raw coordinates, not a geocoded
  /// label - reverse-geocode on-device (same source as the history tile's
  /// endpoint labels), falling back to the trimmed lat/lng.
  Future<PlaceModel> _placeFor(TripCoordinate? point, String fallbackLabel) async {
    if (point == null) {
      return PlaceModel.fromCoordinate(label: fallbackLabel, lat: 0, lng: 0);
    }
    final address = await locationService.getAddressFromLatLng(point.lat, point.lng);
    final label = (address == null || address.trim().isEmpty)
        ? '${point.lat.toStringAsFixed(4)}, ${point.lng.toStringAsFixed(4)}'
        : address;
    return PlaceModel.fromCoordinate(label: label, lat: point.lat, lng: point.lng);
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

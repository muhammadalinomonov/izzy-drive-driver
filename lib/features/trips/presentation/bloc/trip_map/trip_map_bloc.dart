import 'package:injectable/injectable.dart';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/core/location_service.dart';
import 'package:taxi_app/features/trips/data/model/fuel_station_model.dart';
import 'package:taxi_app/features/trips/data/model/place_model.dart';
import 'package:taxi_app/features/trips/data/model/trip_model.dart';
import 'package:taxi_app/features/trips/data/repo/fuel_stations_repo_impl.dart';
import 'package:taxi_app/features/trips/data/source/fuel_stations_data_source.dart';
import 'package:taxi_app/features/trips/data/source/recent_places_store.dart';
import 'package:taxi_app/features/trips/data/source/trips_data_source.dart';
import 'package:taxi_app/features/trips/domain/repo/fuel_stations_repo.dart';
import 'package:taxi_app/features/trips/domain/repo/trips_repo.dart';

part 'trip_map_event.dart';
part 'trip_map_state.dart';

@injectable
class TripMapBloc extends Bloc<TripMapEvent, TripMapState> {
  final TripsRepo repo;
  final LocationService locationService;

  /// Nearby fuel stations. Currently backed by a placeholder implementation -
  /// see [FuelStationsRepo] - so only that class changes when the API lands.
  final FuelStationsRepo fuelStationsRepo;

  /// Search radius for Gas Station mode: 20 miles, per the task brief.
  static const double fuelRadiusMeters = 20 * 1609.344;

  /// Task brief asks for ~300-500ms; 400 sits in the middle and keeps the
  /// suggestion list from flickering on fast typists.
  static const Duration debounce = Duration(milliseconds: 400);

  Timer? _debounceTimer;

  /// Aborts the in-flight places request when newer input arrives, so a slow
  /// early response can't overwrite the suggestions for a later query.
  CancelToken? _inFlight;

  /// [fuelStationsRepo] is optional and defaults to the placeholder
  /// implementation. That keeps injectable's generated registration valid
  /// without a codegen run, and leaves the seam open: pass the real repository
  /// here (or register it) once the nearby-stations endpoint exists.
  TripMapBloc({
    required this.repo,
    required this.locationService,
    FuelStationsRepo? fuelStationsRepo,
  })  : fuelStationsRepo = fuelStationsRepo ??
            FuelStationsRepoImpl(dataSource: FuelStationsDataSource()),
        super(const TripMapState()) {
    on<TripMapStarted>(_onStarted);
    on<TripMapFieldFocused>(_onFieldFocused);
    on<TripMapQueryChanged>(_onQueryChanged);
    on<TripMapSearchRequested>(_onSearchRequested);
    on<TripMapPlaceSelected>(_onPlaceSelected);
    on<TripMapSearchDismissed>(_onSearchDismissed);
    on<TripMapContinuePressed>(_onContinuePressed);
    on<TripMapGasStationModeToggled>(_onGasStationModeToggled);
    on<TripMapFuelStationsRequested>(_onFuelStationsRequested);
    on<TripMapFuelStationSelected>(_onFuelStationSelected);
  }

  // ── Nearby Fuel Stations ──────────────────────────────────────────────────

  Future<void> _onGasStationModeToggled(
    TripMapGasStationModeToggled event,
    Emitter<TripMapState> emit,
  ) async {
    if (state.fuelMode) {
      // Leaving the mode clears the markers but deliberately keeps whatever
      // origin/destination the driver ended up with - they may have picked a
      // station and want to keep planning that trip.
      emit(state.copyWith(
        fuelMode: false,
        fuelStatus: TripMapFuelStatus.idle,
        fuelStations: const [],
        selectedStationId: '',
        fuelError: '',
      ));
      return;
    }

    emit(state.copyWith(fuelMode: true));
    await _loadFuelStations(emit);
  }

  Future<void> _onFuelStationsRequested(
    TripMapFuelStationsRequested event,
    Emitter<TripMapState> emit,
  ) async {
    if (!state.fuelMode) return;
    await _loadFuelStations(emit);
  }

  Future<void> _loadFuelStations(Emitter<TripMapState> emit) async {
    // Stations are searched around the driver, so an origin is required. It is
    // resolved on page open; if that failed there is nothing to search around.
    final origin = state.origin?.coordinate;
    if (origin == null) {
      emit(state.copyWith(
        fuelStatus: TripMapFuelStatus.failure,
        fuelError: 'tripMap.fuelNeedsLocation',
      ));
      return;
    }

    emit(state.copyWith(
      fuelStatus: TripMapFuelStatus.loading,
      fuelError: '',
    ));

    final response = await fuelStationsRepo.getNearbyFuelStations(
      currentLocation: origin,
      radiusMeters: fuelRadiusMeters,
    );

    if (response.errorText.isNotEmpty) {
      emit(state.copyWith(
        fuelStatus: TripMapFuelStatus.failure,
        fuelError: response.errorText,
      ));
      return;
    }

    emit(state.copyWith(
      fuelStatus: TripMapFuelStatus.success,
      fuelStations: response.data ?? const [],
      fuelError: '',
    ));
  }

  /// Picking a station fills both fields at once: origin stays the driver's
  /// current location and the station becomes the destination, so Continue is
  /// immediately available and the normal routing flow takes over unchanged.
  void _onFuelStationSelected(
    TripMapFuelStationSelected event,
    Emitter<TripMapState> emit,
  ) {
    final destination = event.station.toPlace();
    emit(state.copyWith(
      destination: destination,
      selectedStationId: event.station.id,
      // Drives the page's controller/camera sync, same as a searched pick.
      lastSelected: destination,
      lastSelectedField: TripMapField.destination,
      selectionTick: state.selectionTick + 1,
      activeField: TripMapField.none,
      searchStatus: TripMapSearchStatus.idle,
      query: '',
      suggestions: const [],
    ));
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    _inFlight?.cancel();
    return super.close();
  }

  Future<void> _onStarted(
    TripMapStarted event,
    Emitter<TripMapState> emit,
  ) async {
    emit(state.copyWith(
      recents: RecentPlacesStore.load(),
      originStatus: TripMapFieldStatus.loading,
    ));

    final position = await locationService.getCurrentLocation();
    if (position == null) {
      // No GPS fix (denied or unavailable): leave the field empty and
      // editable rather than blocking the flow - the driver can type an
      // origin by hand.
      emit(state.copyWith(originStatus: TripMapFieldStatus.failure));
      return;
    }

    // Reverse-geocode for a human label; the coordinates are authoritative
    // either way, so a failed lookup degrades to a lat/lng label.
    final address = await locationService.getAddressFromLatLng(
      position.latitude,
      position.longitude,
    );
    final label = (address == null || address.trim().isEmpty)
        ? '${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)}'
        : address;

    emit(state.copyWith(
      originStatus: TripMapFieldStatus.success,
      origin: PlaceModel.fromCoordinate(
        label: label,
        lat: position.latitude,
        lng: position.longitude,
      ),
    ));
  }

  void _onFieldFocused(TripMapFieldFocused event, Emitter<TripMapState> emit) {
    if (state.activeField == event.field) return;
    // Switching fields abandons the previous field's query and suggestions.
    _cancelPending();
    emit(state.copyWith(
      activeField: event.field,
      query: '',
      suggestions: const [],
      searchStatus: TripMapSearchStatus.idle,
      errorMessage: '',
    ));
  }

  void _onQueryChanged(TripMapQueryChanged event, Emitter<TripMapState> emit) {
    final query = event.query;
    _cancelPending();

    if (query.trim().length < TripsDataSource.minQueryLength) {
      // Below the backend's 3-char minimum: show history again instead of
      // firing a request that would 422.
      emit(state.copyWith(
        query: query,
        suggestions: const [],
        searchStatus: TripMapSearchStatus.idle,
        errorMessage: '',
      ));
      return;
    }

    emit(state.copyWith(query: query, searchStatus: TripMapSearchStatus.loading));
    _debounceTimer = Timer(debounce, () {
      if (isClosed) return;
      add(TripMapSearchRequested(query));
    });
  }

  Future<void> _onSearchRequested(
    TripMapSearchRequested event,
    Emitter<TripMapState> emit,
  ) async {
    final token = CancelToken();
    _inFlight = token;
    final response = await repo.searchPlaces(event.query, cancelToken: token);

    // A newer keystroke already superseded this request.
    if (token.isCancelled || event.query != state.query) return;
    _inFlight = null;

    if (response.errorCode == 'REQUEST_CANCELLED') return;

    if (response.errorText.isEmpty && response.data != null) {
      final items = response.data!;
      emit(state.copyWith(
        suggestions: items,
        searchStatus: items.isEmpty
            ? TripMapSearchStatus.empty
            : TripMapSearchStatus.success,
        errorMessage: '',
      ));
    } else {
      emit(state.copyWith(
        suggestions: const [],
        searchStatus: TripMapSearchStatus.failure,
        errorMessage: response.errorText,
      ));
    }
  }

  Future<void> _onPlaceSelected(
    TripMapPlaceSelected event,
    Emitter<TripMapState> emit,
  ) async {
    _cancelPending();
    final field = event.field ?? state.activeField;
    // Nothing focused and no explicit target - ignore rather than guess which
    // field the driver meant to fill.
    if (field == TripMapField.none) return;

    final recents = await RecentPlacesStore.add(event.place);
    emit(state.copyWith(
      origin: field == TripMapField.origin ? event.place : state.origin,
      destination:
          field == TripMapField.destination ? event.place : state.destination,
      originStatus: field == TripMapField.origin
          ? TripMapFieldStatus.success
          : state.originStatus,
      // Selection completes the search: drop suggestions, unfocus, restore
      // the history list.
      activeField: TripMapField.none,
      query: '',
      suggestions: const [],
      searchStatus: TripMapSearchStatus.idle,
      recents: recents,
      errorMessage: '',
      lastSelected: event.place,
      lastSelectedField: field,
      selectionTick: state.selectionTick + 1,
    ));
  }

  void _onSearchDismissed(
    TripMapSearchDismissed event,
    Emitter<TripMapState> emit,
  ) {
    _cancelPending();
    emit(state.copyWith(
      activeField: TripMapField.none,
      query: '',
      suggestions: const [],
      searchStatus: TripMapSearchStatus.idle,
      errorMessage: '',
    ));
  }

  Future<void> _onContinuePressed(
    TripMapContinuePressed event,
    Emitter<TripMapState> emit,
  ) async {
    final origin = state.origin;
    final destination = state.destination;
    if (origin == null || destination == null) return;

    emit(state.copyWith(continueStatus: TripMapContinueStatus.loading));
    final response = await repo.createRoute(
      origin: origin.coordinate,
      destination: destination.coordinate,
    );

    if (response.errorText.isEmpty && response.data != null) {
      emit(state.copyWith(
        continueStatus: TripMapContinueStatus.idle,
        createdRoute: response.data,
        continueTick: state.continueTick + 1,
        errorMessage: '',
      ));
    } else {
      emit(state.copyWith(
        continueStatus: TripMapContinueStatus.failure,
        continueError: response.errorText,
      ));
    }
  }

  void _cancelPending() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _inFlight?.cancel();
    _inFlight = null;
  }
}

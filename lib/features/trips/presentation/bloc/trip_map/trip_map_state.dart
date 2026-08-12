part of 'trip_map_bloc.dart';

/// Which text field is the active search target. Only one at a time.
enum TripMapField { none, origin, destination }

enum TripMapFieldStatus { initial, loading, success, failure }

enum TripMapSearchStatus { idle, loading, success, empty, failure }

/// State of the `POST /toll-routes` call fired by Continue.
enum TripMapContinueStatus { idle, loading, failure }

/// Lifecycle of the nearby-stations request. `empty` is folded into `success`
/// with an empty list - see [TripMapState.fuelIsEmpty] - so the UI has one
/// place to branch on.
enum TripMapFuelStatus { idle, loading, success, failure }

/// Lifecycle of a "my location" press. `failure` means no GPS fix was
/// available, which the page reports the same way a failed station search
/// does - the driver's fix is the missing ingredient in both.
enum TripMapRecenterStatus { idle, loading, failure }

class TripMapState extends Equatable {
  final TripMapField activeField;
  final TripMapFieldStatus originStatus;
  final TripMapSearchStatus searchStatus;

  final PlaceModel? origin;
  final PlaceModel? destination;

  final String query;
  final List<PlaceModel> suggestions;
  final List<PlaceModel> recents;
  final String errorMessage;

  /// Last picked place and the field it filled - the page listens on these to
  /// drive the Mapbox camera and markers, which live outside the bloc.
  final PlaceModel? lastSelected;
  final TripMapField lastSelectedField;

  /// Bumped on every selection. Without it, picking the SAME recent twice
  /// would produce an equal state, bloc would skip the emit, and the camera
  /// would not return to the place after the driver panned away.
  final int selectionTick;

  final TripMapContinueStatus continueStatus;
  final String continueError;

  /// The route request created by the last successful Continue. The page
  /// listens on [continueTick] (not this field alone) to navigate, since
  /// re-pricing the exact same origin/destination pair would otherwise
  /// produce an equal [TripModel] and skip the emit.
  final TripModel? createdRoute;
  final int continueTick;

  // ── Nearby Fuel Stations ────────────────────────────────────────────────

  /// True while "Nearby Fuel Stations" mode is on: the map shows station
  /// markers and tapping one fills both location fields.
  final bool fuelMode;

  final TripMapFuelStatus fuelStatus;
  final List<FuelStationModel> fuelStations;

  /// Station the driver picked, so its marker can be highlighted.
  final String selectedStationId;

  final String fuelError;

  // ── My location ─────────────────────────────────────────────────────────

  final TripMapRecenterStatus recenterStatus;

  /// Where the camera should fly on the latest recenter. Held separately from
  /// [origin] so recentring the view never rewrites a destination the driver
  /// typed by hand.
  final TripCoordinate? recenterTarget;

  /// Bumped per press, so recentring twice from the same spot still moves the
  /// camera back after the driver has panned away.
  final int recenterTick;

  const TripMapState({
    this.activeField = TripMapField.none,
    this.originStatus = TripMapFieldStatus.initial,
    this.searchStatus = TripMapSearchStatus.idle,
    this.origin,
    this.destination,
    this.query = '',
    this.suggestions = const [],
    this.recents = const [],
    this.errorMessage = '',
    this.lastSelected,
    this.lastSelectedField = TripMapField.none,
    this.selectionTick = 0,
    this.continueStatus = TripMapContinueStatus.idle,
    this.continueError = '',
    this.createdRoute,
    this.continueTick = 0,
    this.fuelMode = false,
    this.fuelStatus = TripMapFuelStatus.idle,
    this.fuelStations = const [],
    this.selectedStationId = '',
    this.fuelError = '',
    this.recenterStatus = TripMapRecenterStatus.idle,
    this.recenterTarget,
    this.recenterTick = 0,
  });

  /// Suggestions replace the history list only while a search is live.
  bool get isSearching =>
      activeField != TripMapField.none &&
      searchStatus != TripMapSearchStatus.idle;

  bool get canContinue => origin != null && destination != null;

  /// Fuel mode is on but the search came back with nothing in range.
  bool get fuelIsEmpty =>
      fuelMode &&
      fuelStatus == TripMapFuelStatus.success &&
      fuelStations.isEmpty;

  static const _sentinel = Object();

  TripMapState copyWith({
    TripMapField? activeField,
    TripMapFieldStatus? originStatus,
    TripMapSearchStatus? searchStatus,
    Object? origin = _sentinel,
    Object? destination = _sentinel,
    String? query,
    List<PlaceModel>? suggestions,
    List<PlaceModel>? recents,
    String? errorMessage,
    Object? lastSelected = _sentinel,
    TripMapField? lastSelectedField,
    int? selectionTick,
    TripMapContinueStatus? continueStatus,
    String? continueError,
    Object? createdRoute = _sentinel,
    int? continueTick,
    bool? fuelMode,
    TripMapFuelStatus? fuelStatus,
    List<FuelStationModel>? fuelStations,
    String? selectedStationId,
    String? fuelError,
    TripMapRecenterStatus? recenterStatus,
    Object? recenterTarget = _sentinel,
    int? recenterTick,
  }) {
    return TripMapState(
      activeField: activeField ?? this.activeField,
      originStatus: originStatus ?? this.originStatus,
      searchStatus: searchStatus ?? this.searchStatus,
      origin: identical(origin, _sentinel) ? this.origin : origin as PlaceModel?,
      destination: identical(destination, _sentinel)
          ? this.destination
          : destination as PlaceModel?,
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      recents: recents ?? this.recents,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSelected: identical(lastSelected, _sentinel)
          ? this.lastSelected
          : lastSelected as PlaceModel?,
      lastSelectedField: lastSelectedField ?? this.lastSelectedField,
      selectionTick: selectionTick ?? this.selectionTick,
      continueStatus: continueStatus ?? this.continueStatus,
      continueError: continueError ?? this.continueError,
      createdRoute: identical(createdRoute, _sentinel)
          ? this.createdRoute
          : createdRoute as TripModel?,
      continueTick: continueTick ?? this.continueTick,
      fuelMode: fuelMode ?? this.fuelMode,
      fuelStatus: fuelStatus ?? this.fuelStatus,
      fuelStations: fuelStations ?? this.fuelStations,
      selectedStationId: selectedStationId ?? this.selectedStationId,
      fuelError: fuelError ?? this.fuelError,
      recenterStatus: recenterStatus ?? this.recenterStatus,
      recenterTarget: identical(recenterTarget, _sentinel)
          ? this.recenterTarget
          : recenterTarget as TripCoordinate?,
      recenterTick: recenterTick ?? this.recenterTick,
    );
  }

  @override
  List<Object?> get props => [
        activeField,
        originStatus,
        searchStatus,
        origin,
        destination,
        query,
        suggestions,
        recents,
        errorMessage,
        lastSelected,
        lastSelectedField,
        selectionTick,
        continueStatus,
        continueError,
        createdRoute,
        continueTick,
        fuelMode,
        fuelStatus,
        fuelStations.length,
        selectedStationId,
        fuelError,
        recenterStatus,
        recenterTick,
      ];
}

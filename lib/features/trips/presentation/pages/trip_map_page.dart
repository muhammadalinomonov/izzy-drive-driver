import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:taxi_app/core/components/app_snack_bar.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/features/trips/data/model/fuel_station_model.dart';
import 'package:taxi_app/features/trips/data/model/place_model.dart';
import 'package:taxi_app/features/trips/data/model/trip_model.dart';
import 'package:taxi_app/features/trips/presentation/bloc/trip_map/trip_map_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/core/constants/color/app_icons.dart';
import 'package:taxi_app/core/session/premium_session.dart';
import 'package:taxi_app/features/trips/presentation/pages/route_overview_page.dart';
import 'package:taxi_app/features/trips/presentation/utils/marker_icon.dart';
import 'package:taxi_app/features/trips/presentation/widgets/location_fields_card.dart';
import 'package:taxi_app/features/trips/presentation/widgets/marker_info_sheet.dart';
import 'package:taxi_app/features/trips/presentation/widgets/place_list_tile.dart';
import 'package:taxi_app/features/trips/presentation/widgets/premium_support_button.dart';
import 'package:taxi_app/routes/pages.dart';

/// Trip planning entry point (docs/ui/2.png + 3.png): a full-screen Mapbox map
/// with a draggable sheet holding the origin/destination fields, recent
/// history, and live `mobile/places` suggestions.
///
/// The bloc owns search state; the map camera and markers are imperative
/// Mapbox calls driven from a BlocListener.
class TripMapPage extends StatefulWidget {
  const TripMapPage({super.key});

  @override
  State<TripMapPage> createState() => _TripMapPageState();
}

class _TripMapPageState extends State<TripMapPage> {
  static const double _collapsed = 0.28;
  static const double _half = 0.55;
  static const double _expanded = 0.92;

  /// Height of the right-hand control column - the two zoom buttons and the
  /// my-location button, plus the gaps between them. Used to stop the column
  /// sliding off the top as the sheet expands. Premium adds the Support button
  /// plus its gap, so the ceiling has to account for both layouts.
  static const double _zoomStackHeight = 44 + 12 + 44 + 12 + 44;
  static const double _supportButtonSpacing = 12;

  void _onGasStation() {
    FocusManager.instance.primaryFocus?.unfocus();
    context.read<TripMapBloc>().add(const TripMapGasStationModeToggled());
  }

  final _sheetController = DraggableScrollableController();

  /// Mirrors the sheet's current extent so the zoom buttons can ride just
  /// above it instead of hiding underneath when the driver drags it up.
  final _sheetExtent = ValueNotifier<double>(_half);

  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _originFocus = FocusNode();
  final _destinationFocus = FocusNode();

  mapbox.MapboxMap? _map;
  mapbox.PointAnnotationManager? _annotations;
  mapbox.PointAnnotation? _originMarker;
  mapbox.PointAnnotation? _destinationMarker;

  /// Fuel-station markers live in their own manager so the whole set can be
  /// dropped when the mode is switched off without touching origin/destination.
  mapbox.PointAnnotationManager? _stationAnnotations;

  /// Maps a station marker back to its station, so a tap can be resolved.
  final Map<int, FuelStationModel> _stationByAnnotationId = {};

  /// Station list the markers were last drawn for, so identical rebuilds are
  /// skipped rather than redrawing every marker on each state emission.
  List<FuelStationModel> _renderedStations = const [];
  String _renderedSelectedStationId = '';

  /// Recenter tick the camera has already flown for, so one press moves the
  /// camera exactly once.
  int _handledRecenterTick = 0;

  /// A camera target that arrived before Mapbox finished initialising. On a
  /// cold start the GPS fix can beat [_onMapCreated], and a fly issued against
  /// a null map is simply lost - leaving the driver staring at the fallback
  /// centre - so it is held here and replayed once the map exists.
  TripCoordinate? _pendingCameraTarget;

  /// Tashkent fallback until the GPS fix lands.
  static final mapbox.Position _fallback = mapbox.Position(69.2401, 41.2995);

  @override
  void initState() {
    super.initState();
    _originFocus.addListener(_onFocusChanged);
    _destinationFocus.addListener(_onFocusChanged);
    _sheetController.addListener(_onSheetMoved);
    context.read<TripMapBloc>().add(const TripMapStarted());
  }

  /// The controller is a ChangeNotifier over the sheet's live size, so this
  /// fires on every frame of a drag, a fling, and the programmatic
  /// animateTo calls in _expandSheet / _showWholeMap alike.
  void _onSheetMoved() {
    if (!_sheetController.isAttached) return;
    _sheetExtent.value = _sheetController.size;
  }

  @override
  void dispose() {
    _originFocus.removeListener(_onFocusChanged);
    _destinationFocus.removeListener(_onFocusChanged);
    _originFocus.dispose();
    _destinationFocus.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _sheetController.removeListener(_onSheetMoved);
    _sheetController.dispose();
    _sheetExtent.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    final bloc = context.read<TripMapBloc>();
    if (_originFocus.hasFocus) {
      bloc.add(const TripMapFieldFocused(TripMapField.origin));
      _expandSheet();
    } else if (_destinationFocus.hasFocus) {
      bloc.add(const TripMapFieldFocused(TripMapField.destination));
      _expandSheet();
    } else if (bloc.state.activeField != TripMapField.none) {
      bloc.add(const TripMapSearchDismissed());
    }
  }

  /// Typing needs the whole list visible, so focusing a field lifts the sheet.
  void _expandSheet() {
    if (!_sheetController.isAttached) return;
    if (_sheetController.size >= _expanded - 0.01) return;
    _sheetController.animateTo(
      _expanded,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// "Map" button: drop the sheet to its collapsed size and dismiss the
  /// keyboard so the map is fully visible. Unfocusing also clears the active
  /// field, which restores the history list underneath.
  void _showWholeMap() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_sheetController.isAttached) return;
    _sheetController.animateTo(
      _collapsed,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _onMapCreated(mapbox.MapboxMap map) {
    _map = map;
    map.style.setProjection(
      mapbox.StyleProjection(name: mapbox.StyleProjectionName.mercator),
    );
    map.scaleBar.updateSettings(mapbox.ScaleBarSettings(enabled: false));
    map.compass.updateSettings(mapbox.CompassSettings(enabled: false));

    final pending = _pendingCameraTarget;
    if (pending != null) {
      _pendingCameraTarget = null;
      _flyToCurrentLocation(pending);
    }
  }

  Future<void> _syncMarker(TripMapField field, PlaceModel place) async {
    final map = _map;
    if (map == null) return;
    _annotations ??= await map.annotations.createPointAnnotationManager();
    final manager = _annotations!;
    final point = mapbox.Point(
      coordinates: mapbox.Position(place.coordinate.lng, place.coordinate.lat),
    );

    final isOrigin = field == TripMapField.origin;
    final png = await rasterizeMarkerSvg(
      isOrigin
          ? 'assets/icons/currner_point_marker.svg'
          : 'assets/icons/finish_marker.svg',
    );
    if (!mounted) return;

    // Mapbox annotations are immutable handles - move one by deleting and
    // recreating it, keeping at most one marker per field.
    final existing = isOrigin ? _originMarker : _destinationMarker;
    if (existing != null) {
      await manager.delete(existing);
    }
    final created = await manager.create(
      mapbox.PointAnnotationOptions(
        geometry: point,
        image: png,
        iconSize: 1.7,
        iconAnchor: mapbox.IconAnchor.BOTTOM,
      ),
    );
    if (!mounted) return;
    if (field == TripMapField.origin) {
      _originMarker = created;
    } else {
      _destinationMarker = created;
    }

    await map.flyTo(
      mapbox.CameraOptions(center: point, zoom: 14.0),
      mapbox.MapAnimationOptions(duration: 700),
    );
  }

  /// Draws (or clears) the fuel-station markers.
  ///
  /// Skipped entirely when neither the station list nor the selection has
  /// changed - this runs from a BlocListener that also fires for unrelated
  /// state like search suggestions.
  Future<void> _syncStationMarkers(TripMapState state) async {
    final map = _map;
    if (map == null) return;

    final stations = state.fuelMode ? state.fuelStations : const <FuelStationModel>[];
    final sameList = identical(_renderedStations, stations) ||
        (_renderedStations.length == stations.length &&
            (stations.isEmpty ||
                _renderedStations.first.id == stations.first.id));
    if (sameList && _renderedSelectedStationId == state.selectedStationId) {
      return;
    }
    _renderedStations = stations;
    _renderedSelectedStationId = state.selectedStationId;

    _stationAnnotations ??= await map.annotations.createPointAnnotationManager();
    final manager = _stationAnnotations!;
    if (!mounted) return;

    await manager.deleteAll();
    _stationByAnnotationId.clear();
    if (!mounted || stations.isEmpty) return;

    // Rasterized at the size it is drawn at rather than at 88 and scaled up
    // with iconSize: upscaling a bitmap softens the pump art and the price
    // pin's edges, and this marker has to stay readable against busy roads.
    final png = await rasterizeMarkerSvg(AppIcons.gasStationMarker, height: 140);
    if (!mounted) return;

    for (final station in stations) {
      final isSelected = station.id == state.selectedStationId;
      final created = await manager.create(
        mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position(
              station.coordinate.lng,
              station.coordinate.lat,
            ),
          ),
          image: png,
          // The selected station is scaled up rather than recoloured: the
          // marker art is a fixed multi-colour asset, so size is the only
          // honest highlight available without a second bitmap.
          iconSize: isSelected ? 1.25 : 1.0,
          iconAnchor: mapbox.IconAnchor.BOTTOM,
        ),
      );
      if (!mounted) return;
      _stationByAnnotationId[created.id.hashCode] = station;
    }

    // Registered once the markers exist; the tap is resolved back to its
    // station via [_stationByAnnotationId].
    manager.tapEvents(
      onTap: (annotation) {
        final station = _stationByAnnotationId[annotation.id.hashCode];
        if (station != null) _onStationTapped(station);
      },
    );
  }

  /// Tapping a station highlights it and opens the shared marker sheet, in its
  /// premium or standard layout. The destination is only set if the driver
  /// acts on the sheet, so a tap to read the price doesn't hijack the route
  /// they were planning.
  Future<void> _onStationTapped(FuelStationModel station) async {
    final bloc = context.read<TripMapBloc>();
    bloc.add(TripMapMarkerHighlighted(station.id));

    final action = await showMarkerInfoSheet(
      context,
      info: MarkerInfo.fromFuelStation(station),
      showActionButton: true,
      premium: PremiumSession.isPremium,
      // Dismissing without acting drops the highlight again.
      onDismissed: () => bloc.add(const TripMapMarkerHighlighted('')),
    );
    if (action == null || !mounted) return;

    switch (action) {
      // Fills both fields and prices the trip in one step; the route-overview
      // push is handled by the same continueTick listener Continue uses.
      case MarkerSheetAction.drive:
        bloc.add(TripMapFuelStationSelected(station, startRouting: true));
      // Premium-only. The refuelling-request API is not part of this task, so
      // this lands on the existing premium support screen (as the route
      // support flow does) with the station kept as the pending destination.
      case MarkerSheetAction.requestRefueling:
        bloc.add(TripMapFuelStationSelected(station));
        context.push(Pages.supportMessage);
    }
  }

  /// Frames origin and the chosen station together, so the driver sees the
  /// whole trip the moment they pick one.
  Future<void> _fitToStation(PlaceModel origin, PlaceModel destination) async {
    final map = _map;
    if (map == null) return;
    final camera = await map.cameraForCoordinatesPadding(
      [
        mapbox.Point(
          coordinates:
              mapbox.Position(origin.coordinate.lng, origin.coordinate.lat),
        ),
        mapbox.Point(
          coordinates: mapbox.Position(
            destination.coordinate.lng,
            destination.coordinate.lat,
          ),
        ),
      ],
      mapbox.CameraOptions(),
      mapbox.MbxEdgeInsets(top: 90, left: 60, bottom: 340, right: 60),
      null,
      null,
    );
    if (!mounted) return;
    await map.flyTo(camera, mapbox.MapAnimationOptions(duration: 700));
  }

  void _onRecenter() {
    FocusManager.instance.primaryFocus?.unfocus();
    context.read<TripMapBloc>().add(const TripMapRecenterRequested());
  }

  /// Flies to the driver's fresh fix. A zoom already tighter than 14 is kept -
  /// someone who zoomed in to read street names wants their zoom back along
  /// with their position, not a reset to the default.
  Future<void> _flyToCurrentLocation(TripCoordinate target) async {
    final map = _map;
    if (map == null) {
      _pendingCameraTarget = target;
      return;
    }
    final camera = await map.getCameraState();
    if (!mounted) return;
    await map.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(target.lng, target.lat),
        ),
        zoom: camera.zoom < 14 ? 15.0 : camera.zoom,
      ),
      mapbox.MapAnimationOptions(duration: 700),
    );
  }

  Future<void> _zoomBy(double delta) async {
    final map = _map;
    if (map == null) return;
    final camera = await map.getCameraState();
    await map.easeTo(
      mapbox.CameraOptions(zoom: camera.zoom + delta),
      mapbox.MapAnimationOptions(duration: 220),
    );
  }

  void _onQueryChanged(String value) {
    context.read<TripMapBloc>().add(TripMapQueryChanged(value));
  }

  void _onFieldTapped(TripMapField field) {
    context.read<TripMapBloc>().add(TripMapFieldFocused(field));
  }

  void _selectPlace(PlaceModel place) {
    final bloc = context.read<TripMapBloc>();
    // A history tap with nothing focused has no target field; default to the
    // destination, which is the one the driver is normally filling.
    final field = bloc.state.activeField == TripMapField.none
        ? TripMapField.destination
        : bloc.state.activeField;
    FocusManager.instance.primaryFocus?.unfocus();
    bloc.add(TripMapPlaceSelected(place, field: field));
  }

  void _onStateChanged(BuildContext context, TripMapState state) {
    // Keep the controllers in sync with the bloc without fighting the user's
    // cursor: only overwrite a field that is not the active search target.
    if (state.activeField != TripMapField.origin) {
      final text = state.origin?.fieldLabel ?? '';
      if (_originController.text != text) _originController.text = text;
    }
    if (state.activeField != TripMapField.destination) {
      final text = state.destination?.fieldLabel ?? '';
      if (_destinationController.text != text) {
        _destinationController.text = text;
      }
    }
  }

  void _onContinue() {
    final bloc = context.read<TripMapBloc>();
    if (!bloc.state.canContinue ||
        bloc.state.continueStatus == TripMapContinueStatus.loading) {
      return;
    }
    bloc.add(const TripMapContinuePressed());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      resizeToAvoidBottomInset: false,
      body: BlocConsumer<TripMapBloc, TripMapState>(
        listenWhen: (p, c) =>
            p.selectionTick != c.selectionTick ||
            p.origin != c.origin ||
            p.destination != c.destination ||
            p.activeField != c.activeField ||
            p.continueTick != c.continueTick ||
            p.continueStatus != c.continueStatus ||
            p.fuelMode != c.fuelMode ||
            p.fuelStatus != c.fuelStatus ||
            p.fuelStations.length != c.fuelStations.length ||
            p.selectedStationId != c.selectedStationId ||
            p.recenterTick != c.recenterTick ||
            p.recenterStatus != c.recenterStatus ||
            p.originStatus != c.originStatus,
        listener: (context, state) {
          _onStateChanged(context, state);
          _syncStationMarkers(state);

          final place = state.lastSelected;
          if (place != null &&
              state.lastSelectedField != TripMapField.none &&
              state.selectionTick > 0) {
            // A station pick frames both ends at once; an ordinary search pick
            // flies to the single place it selected.
            final origin = state.origin;
            if (state.selectedStationId.isNotEmpty && origin != null) {
              _syncMarker(state.lastSelectedField, place);
              _fitToStation(origin, place);
            } else {
              _syncMarker(state.lastSelectedField, place);
            }
          }
          if (state.fuelStatus == TripMapFuelStatus.failure &&
              state.fuelError.isNotEmpty) {
            AppSnackBar.showError(
              context,
              state.fuelError == 'tripMap.fuelNeedsLocation'
                  ? 'tripMap.fuelNeedsLocation'.tr()
                  : state.fuelError,
            );
          }
          // An empty catalogue answer is a valid result, not an error - but
          // silently drawing no markers reads as a broken button, so it gets
          // said out loud.
          if (state.fuelIsEmpty) {
            AppSnackBar.showWarning(context, 'tripMap.fuelNoStations'.tr());
          }
          // Tick-guarded: this listener also fires for selections and fuel
          // state, and an unguarded fly would drag the camera back to the
          // driver every time one of those changed.
          final recenterTarget = state.recenterTarget;
          if (recenterTarget != null &&
              state.recenterTick != _handledRecenterTick) {
            _handledRecenterTick = state.recenterTick;
            _flyToCurrentLocation(recenterTarget);
          }
          // Both the my-location press and the opening fix report a missing
          // location the same way: the fields stay editable either way, so the
          // driver needs telling why the map did not move.
          if (state.recenterStatus == TripMapRecenterStatus.failure ||
              state.originStatus == TripMapFieldStatus.failure) {
            AppSnackBar.showWarning(
              context,
              'tripMap.locationUnavailable'.tr(),
            );
          }
          if (state.continueStatus == TripMapContinueStatus.failure &&
              state.continueError.isNotEmpty) {
            AppSnackBar.showError(context, state.continueError);
          }
          final route = state.createdRoute;
          if (route != null &&
              state.continueTick > 0 &&
              state.origin != null &&
              state.destination != null) {
            context.pushReplacement(
              Pages.routeOverview,
              extra: RouteOverviewArgs(
                trip: route,
                origin: state.origin!,
                destination: state.destination!,
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            fit: StackFit.expand,
            children: [
              mapbox.MapWidget(
                key: const ValueKey('tripPlannerMap'),
                styleUri: mapbox.MapboxStyles.STANDARD,
                onMapCreated: _onMapCreated,
                cameraOptions: mapbox.CameraOptions(
                  center: mapbox.Point(coordinates: _fallback),
                  zoom: 12.0,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CircleButton(
                        icon: Icons.arrow_back,
                        onTap: () => context.pop(),
                      ),
                      // Sits beside the back button rather than centred over
                      // the map: the sheet already owns the lower half and a
                      // centred banner would land on the fallback centre the
                      // driver is waiting to be moved away from.
                      if (state.originStatus == TripMapFieldStatus.loading)
                        const Expanded(child: _LocatingBanner()),
                    ],
                  ),
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: _sheetExtent,
                builder: (context, extent, child) {
                  final size = MediaQuery.sizeOf(context);
                  final topInset = MediaQuery.paddingOf(context).top;
                  // Riding the sheet all the way to _expanded would push the
                  // pair off the top of the screen, so stop them just below
                  // the status bar.
                  final ceiling = math.max(
                    16.0,
                    size.height -
                        topInset -
                        16 -
                        _zoomStackHeight -
                        (PremiumSession.isPremium
                            ? PremiumSupportButton.heightWith(
                                _supportButtonSpacing,
                              )
                            : 0),
                  );
                  return Positioned(
                    right: 16,
                    bottom: (size.height * extent + 16).clamp(16.0, ceiling),
                    child: child!,
                  );
                },
                child: Column(
                  children: [
                    _CircleButton(icon: Icons.add, onTap: () => _zoomBy(1)),
                    const SizedBox(height: 12),
                    _CircleButton(icon: Icons.remove, onTap: () => _zoomBy(-1)),
                    const SizedBox(height: 12),
                    // "My location": takes a fresh fix and flies to it. Sits
                    // with the zoom controls because it is a camera action,
                    // not a change to the trip being planned.
                    _CircleButton(
                      svgAsset: AppIcons.gpsRecenter,
                      loading:
                          state.recenterStatus == TripMapRecenterStatus.loading,
                      onTap: _onRecenter,
                    ),
                    // Premium-only; renders nothing (and takes no space) for
                    // everyone else. Shared with the route overview and
                    // driving mode screens.
                    const PremiumSupportButton(
                      spacingAbove: _supportButtonSpacing,
                    ),
                  ],
                ),
              ),
              _Sheet(
                controller: _sheetController,
                collapsed: _collapsed,
                half: _half,
                expanded: _expanded,
                state: state,
                originController: _originController,
                destinationController: _destinationController,
                originFocus: _originFocus,
                destinationFocus: _destinationFocus,
                onQueryChanged: _onQueryChanged,
                onFieldTapped: _onFieldTapped,
                onSelectPlace: _selectPlace,
                onContinue: _onContinue,
                onGasStation: _onGasStation,
                onShowMap: _showWholeMap,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.controller,
    required this.collapsed,
    required this.half,
    required this.expanded,
    required this.state,
    required this.originController,
    required this.destinationController,
    required this.originFocus,
    required this.destinationFocus,
    required this.onQueryChanged,
    required this.onFieldTapped,
    required this.onSelectPlace,
    required this.onContinue,
    required this.onGasStation,
    required this.onShowMap,
  });

  final DraggableScrollableController controller;
  final double collapsed;
  final double half;
  final double expanded;
  final TripMapState state;
  final TextEditingController originController;
  final TextEditingController destinationController;
  final FocusNode originFocus;
  final FocusNode destinationFocus;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<TripMapField> onFieldTapped;
  final ValueChanged<PlaceModel> onSelectPlace;
  final VoidCallback onContinue;
  final VoidCallback onGasStation;
  final VoidCallback onShowMap;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: half,
      minChildSize: collapsed,
      maxChildSize: expanded,
      snap: true,
      snapSizes: [collapsed, half, expanded],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(28),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColor.grey2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'tripMap.title'.tr(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppColor.black,
                              ),
                            ),
                            const SizedBox(height: 14),
                            LocationFieldsCard(
                              originController: originController,
                              destinationController: destinationController,
                              originFocus: originFocus,
                              destinationFocus: destinationFocus,
                              activeField: state.activeField,
                              originLoading:
                                  state.originStatus ==
                                  TripMapFieldStatus.loading,
                              onChanged: onQueryChanged,
                              onFocused: onFieldTapped,
                              onMapTap: onShowMap,
                            ),
                          ],
                        ),
                      ),
                    ),
                    _ListSection(state: state, onSelectPlace: onSelectPlace),
                  ],
                ),
              ),
              _ContinueBar(
                enabled:
                    state.canContinue &&
                    state.continueStatus != TripMapContinueStatus.loading,
                loading: state.continueStatus == TripMapContinueStatus.loading,
                onPressed: onContinue,
                fuelMode: state.fuelMode,
                fuelLoading: state.fuelStatus == TripMapFuelStatus.loading,
                onGasStation: onGasStation,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Lower half of the sheet: suggestions while searching, otherwise history.
class _ListSection extends StatelessWidget {
  const _ListSection({required this.state, required this.onSelectPlace});

  final TripMapState state;
  final ValueChanged<PlaceModel> onSelectPlace;

  @override
  Widget build(BuildContext context) {
    if (state.isSearching) {
      return switch (state.searchStatus) {
        TripMapSearchStatus.loading => const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator.adaptive()),
          ),
        ),
        TripMapSearchStatus.empty => SliverToBoxAdapter(
          child: _Message(text: 'tripMap.noResults'.tr()),
        ),
        TripMapSearchStatus.failure => SliverToBoxAdapter(
          child: _Message(
            text: state.errorMessage.isEmpty
                ? 'common.somethingWentWrong'.tr()
                : state.errorMessage,
          ),
        ),
        _ => _PlaceSliver(
          places: state.suggestions,
          isHistory: false,
          onSelectPlace: onSelectPlace,
        ),
      };
    }

    if (state.recents.isEmpty) {
      return SliverToBoxAdapter(
        child: _Message(text: 'tripMap.noRecents'.tr()),
      );
    }
    return _PlaceSliver(
      places: state.recents,
      isHistory: true,
      onSelectPlace: onSelectPlace,
    );
  }
}

class _PlaceSliver extends StatelessWidget {
  const _PlaceSliver({
    required this.places,
    required this.isHistory,
    required this.onSelectPlace,
  });

  final List<PlaceModel> places;
  final bool isHistory;
  final ValueChanged<PlaceModel> onSelectPlace;

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: places.length,
      separatorBuilder: (_, __) =>
          Divider(color: AppColor.grey2, height: 1, indent: 52),
      itemBuilder: (context, index) {
        final place = places[index];
        return PlaceListTile(
          place: place,
          isHistory: isHistory,
          onTap: () => onSelectPlace(place),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColor.grey),
        ),
      ),
    );
  }
}

class _ContinueBar extends StatelessWidget {
  const _ContinueBar({
    required this.fuelMode,
    required this.fuelLoading,
    required this.onGasStation,
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  /// Whether Nearby Fuel Stations mode is active.
  final bool fuelMode;

  /// Whether the nearby-stations request is still in flight.
  final bool fuelLoading;
  final VoidCallback onGasStation;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            // Gas Station toggle, per docs/ui/3-1.png: a circular icon button
            // sharing the bar with Continue.
            _GasStationButton(
              active: fuelMode,
              loading: fuelLoading,
              onTap: onGasStation,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: enabled ? onPressed : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColor.kPrimaryColor,
                    disabledBackgroundColor: AppColor.grey2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          'tripMap.continue'.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular Gas Station toggle. Fills with the primary colour while Nearby
/// Fuel Stations mode is on, so the map's station markers have an obvious
/// on-screen source and an obvious way back out.
class _GasStationButton extends StatelessWidget {
  const _GasStationButton({
    required this.active,
    required this.loading,
    required this.onTap,
  });

  final bool active;

  /// The catalogue request is in flight. Shown in place of the icon: fetching
  /// the stations is a network round trip, and without this the button looks
  /// inert until markers appear.
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = active ? Colors.white : AppColor.black;
    return Material(
      color: active ? AppColor.kPrimaryColor : AppColor.white,
      shape: CircleBorder(
        side: BorderSide(color: active ? Colors.transparent : AppColor.grey2),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        // Ignored while loading so a second tap can't cancel the mode out from
        // under the request that is still arriving.
        onTap: loading ? null : onTap,
        child: SizedBox(
          width: 50,
          height: 50,
          child: Center(
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(foreground),
                    ),
                  )
                : SvgPicture.asset(
                    AppIcons.gasStation,
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
                  ),
          ),
        ),
      ),
    );
  }
}

/// "Finding your location…" pill, shown over the map until the opening GPS fix
/// lands and the camera moves off the fallback centre.
class _LocatingBanner extends StatelessWidget {
  const _LocatingBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: AppColor.white,
          elevation: 3,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation(AppColor.kPrimaryColor),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'tripMap.locating'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColor.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A plain white map control - back, zoom in, zoom out, my location. The
/// Support button is its own widget (see [PremiumSupportButton]) because it
/// carries the premium gate and the filled treatment with it.
///
/// Takes either a Material [icon] or an [svgAsset]; the my-location control
/// ships as an SVG, the rest are Material glyphs.
class _CircleButton extends StatelessWidget {
  const _CircleButton({
    this.icon,
    this.svgAsset,
    required this.onTap,
    this.loading = false,
  }) : assert(icon != null || svgAsset != null, 'needs an icon or an asset');

  final IconData? icon;
  final String? svgAsset;
  final VoidCallback onTap;

  /// Shows a spinner instead of the glyph and ignores taps. Used while a GPS
  /// fix is being acquired, which can take a second or two indoors.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final asset = svgAsset;
    return Material(
      color: AppColor.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: loading ? null : onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(AppColor.black),
                    ),
                  )
                : asset != null
                    ? SvgPicture.asset(
                        asset,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          AppColor.black,
                          BlendMode.srcIn,
                        ),
                      )
                    : Icon(icon, size: 20, color: AppColor.black),
          ),
        ),
      ),
    );
  }
}

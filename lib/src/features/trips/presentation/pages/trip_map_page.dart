import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:taxi_app/src/core/components/app_snack_bar.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/features/trips/data/model/place_model.dart';
import 'package:taxi_app/src/features/trips/presentation/bloc/trip_map/trip_map_bloc.dart';
import 'package:taxi_app/src/features/trips/presentation/pages/route_overview_page.dart';
import 'package:taxi_app/src/features/trips/presentation/utils/marker_icon.dart';
import 'package:taxi_app/src/features/trips/presentation/widgets/location_fields_card.dart';
import 'package:taxi_app/src/features/trips/presentation/widgets/place_list_tile.dart';
import 'package:taxi_app/src/routes/pages.dart';

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

  final _sheetController = DraggableScrollableController();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _originFocus = FocusNode();
  final _destinationFocus = FocusNode();

  mapbox.MapboxMap? _map;
  mapbox.PointAnnotationManager? _annotations;
  mapbox.PointAnnotation? _originMarker;
  mapbox.PointAnnotation? _destinationMarker;

  /// Tashkent fallback until the GPS fix lands.
  static final mapbox.Position _fallback = mapbox.Position(69.2401, 41.2995);

  @override
  void initState() {
    super.initState();
    _originFocus.addListener(_onFocusChanged);
    _destinationFocus.addListener(_onFocusChanged);
    context.read<TripMapBloc>().add(const TripMapStarted());
  }

  @override
  void dispose() {
    _originFocus.removeListener(_onFocusChanged);
    _destinationFocus.removeListener(_onFocusChanged);
    _originFocus.dispose();
    _destinationFocus.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _sheetController.dispose();
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
        iconSize: 1.5,
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
            p.continueStatus != c.continueStatus,
        listener: (context, state) {
          _onStateChanged(context, state);
          final place = state.lastSelected;
          if (place != null &&
              state.lastSelectedField != TripMapField.none &&
              state.selectionTick > 0) {
            _syncMarker(state.lastSelectedField, place);
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
            context.push(
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
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: _CircleButton(
                      icon: Icons.arrow_back,
                      onTap: () => context.pop(),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: MediaQuery.sizeOf(context).height * 0.28,
                child: Column(
                  children: [
                    _CircleButton(icon: Icons.add, onTap: () => _zoomBy(1)),
                    const SizedBox(height: 12),
                    _CircleButton(icon: Icons.remove, onTap: () => _zoomBy(-1)),
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                                fontSize: 22,
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
                              originLoading: state.originStatus ==
                                  TripMapFieldStatus.loading,
                              onChanged: onQueryChanged,
                              onFocused: onFieldTapped,
                              onMapTap: onShowMap,
                            ),
                          ],
                        ),
                      ),
                    ),
                    _ListSection(
                      state: state,
                      onSelectPlace: onSelectPlace,
                    ),
                  ],
                ),
              ),
              _ContinueBar(
                enabled: state.canContinue &&
                    state.continueStatus != TripMapContinueStatus.loading,
                loading: state.continueStatus == TripMapContinueStatus.loading,
                onPressed: onContinue,
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
          style: TextStyle(fontSize: 14, color: AppColor.grey),
        ),
      ),
    );
  }
}

class _ContinueBar extends StatelessWidget {
  const _ContinueBar({
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: enabled ? onPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColor.kPrimaryColor,
              disabledBackgroundColor: AppColor.grey2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    'tripMap.continue'.tr(),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, size: 24, color: AppColor.black),
        ),
      ),
    );
  }
}

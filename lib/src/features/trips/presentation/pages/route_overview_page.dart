import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:taxi_app/src/core/components/app_snack_bar.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/utils/polyline_codec.dart';
import 'package:taxi_app/src/features/trips/data/model/place_model.dart';
import 'package:taxi_app/src/features/trips/data/model/trip_model.dart';
import 'package:taxi_app/src/features/trips/presentation/bloc/route_overview/route_overview_bloc.dart';
import 'package:taxi_app/src/features/trips/presentation/pages/driving_mode_page.dart';
import 'package:taxi_app/src/features/trips/presentation/utils/marker_icon.dart';
import 'package:taxi_app/src/routes/pages.dart';

/// Everything the route overview screen needs that isn't already inside the
/// `TripModel` (which only carries raw origin/destination coordinates, not
/// the human-readable labels the driver searched for).
class RouteOverviewArgs {
  final TripModel trip;
  final PlaceModel? origin;
  final PlaceModel? destination;

  /// From the planner, where the route was just calculated and both endpoints
  /// were picked by hand.
  const RouteOverviewArgs({
    required this.trip,
    required PlaceModel this.origin,
    required PlaceModel this.destination,
  });

  /// From the history list: navigate on tap and let the page fetch the full
  /// detail and geocode the endpoints behind its own loading state. [trip] is
  /// the list item, which is enough to place the initial camera.
  const RouteOverviewArgs.pending(this.trip)
      : origin = null,
        destination = null;
}

/// Route overview (docs/ui/8.png): a full-screen map showing every priced
/// alternative, with the selected one emphasized and its toll markers
/// pinned, plus a draggable sheet to switch alternatives and start
/// navigation.
class RouteOverviewPage extends StatefulWidget {
  const RouteOverviewPage({super.key, required this.args});

  final RouteOverviewArgs args;

  @override
  State<RouteOverviewPage> createState() => _RouteOverviewPageState();
}

class _RouteOverviewPageState extends State<RouteOverviewPage> {
  static const double _collapsed = 0.34;
  static const double _half = 0.48;
  static const double _expanded = 0.85;

  /// Both zoom buttons plus the gap between them.
  static const double _zoomStackHeight = 44 + 12 + 44;

  final _sheetController = DraggableScrollableController();

  /// Mirrors the sheet's current extent so the zoom buttons can ride just
  /// above it instead of hiding underneath when the driver drags it up.
  final _sheetExtent = ValueNotifier<double>(_half);

  mapbox.MapboxMap? _map;
  mapbox.PolylineAnnotationManager? _lines;
  mapbox.PointAnnotationManager? _markers;

  /// Only re-draw and re-fit the camera when something the map actually shows
  /// changed, not on every rebuild the bloc triggers.
  String? _renderedKey;

  /// Centre for the very first frame, before any route is drawn. The camera is
  /// re-fitted to the whole route as soon as the detail lands.
  late final mapbox.Position _initialCenter = _centerFor(widget.args);

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(_onSheetMoved);
    context.read<RouteOverviewBloc>().add(
          RouteOverviewStarted(
            originFallbackLabel: 'trips.origin'.tr(),
            destinationFallbackLabel: 'trips.destination'.tr(),
          ),
        );
  }

  static mapbox.Position _centerFor(RouteOverviewArgs args) {
    final point = args.origin?.coordinate ?? args.trip.origin;
    // Geographic centre of the US - a history row with no origin coordinate
    // is a broken record, not a location worth guessing at.
    if (point == null) return mapbox.Position(-95.7129, 37.0902);
    return mapbox.Position(point.lng, point.lat);
  }

  /// Everything `_renderRoute` draws from. Identity is enough: the models are
  /// immutable and replaced wholesale when the detail arrives.
  static String _renderKey(RouteOverviewState state) {
    return '${identityHashCode(state.trip)}|${state.selectedAlternativeId}'
        '|${identityHashCode(state.origin)}|${identityHashCode(state.destination)}';
  }

  /// The controller is a ChangeNotifier over the sheet's live size, so this
  /// fires on every frame of a drag, a fling, and the programmatic animateTo
  /// in _focusStop / _snapHeader alike.
  void _onSheetMoved() {
    if (!_sheetController.isAttached) return;
    _sheetExtent.value = _sheetController.size;
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetMoved);
    _sheetController.dispose();
    _sheetExtent.dispose();
    super.dispose();
  }

  void _onMapCreated(mapbox.MapboxMap map) {
    _map = map;
    map.style.setProjection(
      mapbox.StyleProjection(name: mapbox.StyleProjectionName.mercator),
    );
    map.scaleBar.updateSettings(mapbox.ScaleBarSettings(enabled: false));
    map.compass.updateSettings(mapbox.CompassSettings(enabled: false));
    _renderRoute(context.read<RouteOverviewBloc>().state);
  }

  Future<void> _renderRoute(RouteOverviewState state) async {
    final map = _map;
    if (map == null) return;
    // Nothing to draw until the detail (and with it the endpoints) landed.
    if (!state.isReady) return;
    final key = _renderKey(state);
    if (_renderedKey == key) return;
    _renderedKey = key;

    _lines ??= await map.annotations.createPolylineAnnotationManager();
    _markers ??= await map.annotations.createPointAnnotationManager();
    if (!mounted) return;
    final lines = _lines!;
    final markers = _markers!;
    await lines.deleteAll();
    await markers.deleteAll();
    if (!mounted) return;

    final selected = state.selectedAlternative;
    if (selected == null) return;

    // Alternatives first, thin and muted, so the emphasized selected route
    // draws on top of them.
    for (final alt in state.alternatives) {
      if (alt.id == selected.id) continue;
      final points = decodePolyline(alt.polyline);
      if (points.isEmpty) continue;
      await lines.create(mapbox.PolylineAnnotationOptions(
        geometry: mapbox.LineString(
          coordinates: points.map((p) => mapbox.Position(p.longitude, p.latitude)).toList(),
        ),
        lineColor: AppColor.lightGreyBlue.toARGB32(),
        lineWidth: 4,
      ));
    }

    final selectedPoints = decodePolyline(selected.polyline);
    if (selectedPoints.isNotEmpty) {
      await lines.create(mapbox.PolylineAnnotationOptions(
        geometry: mapbox.LineString(
          coordinates:
              selectedPoints.map((p) => mapbox.Position(p.longitude, p.latitude)).toList(),
        ),
        lineColor: AppColor.kPrimaryColor.toARGB32(),
        lineWidth: 6,
      ));
    }
    if (!mounted) return;

    final originPoint = mapbox.Point(
      coordinates: mapbox.Position(
        state.origin!.coordinate.lng,
        state.origin!.coordinate.lat,
      ),
    );
    final destinationPoint = mapbox.Point(
      coordinates: mapbox.Position(
        state.destination!.coordinate.lng,
        state.destination!.coordinate.lat,
      ),
    );

    final originPng = await rasterizeMarkerSvg('assets/icons/currner_point_marker.svg');
    final destinationPng = await rasterizeMarkerSvg('assets/icons/finish_marker.svg');
    if (!mounted) return;
    await markers.create(mapbox.PointAnnotationOptions(
      geometry: originPoint,
      image: originPng,
      iconSize: 1.4,
      iconAnchor: mapbox.IconAnchor.BOTTOM,
    ));
    await markers.create(mapbox.PointAnnotationOptions(
      geometry: destinationPoint,
      image: destinationPng,
      iconSize: 1.4,
      iconAnchor: mapbox.IconAnchor.BOTTOM,
    ));
    if (!mounted) return;

    // Toll gantries are the only per-station markers the toll API returns
    // coordinates for (no fuel-station coordinates - see route_overview_bloc
    // for context); one pin per entry.
    if (selected.tollMarkers.isNotEmpty) {
      final tollPng = await rasterizeMarkerSvg(AppIcons.tollMarker, height: 72);
      if (!mounted) return;
      for (final toll in selected.tollMarkers) {
        await markers.create(mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position(toll.coordinate.lng, toll.coordinate.lat),
          ),
          image: tollPng,
          iconSize: 1.1,
          iconAnchor: mapbox.IconAnchor.BOTTOM,
        ));
      }
    }
    if (!mounted) return;

    final coordinates = <mapbox.Point>[
      originPoint,
      destinationPoint,
      ...selectedPoints.map((p) => mapbox.Point(coordinates: mapbox.Position(p.longitude, p.latitude))),
    ];
    final sheetHeightPx = MediaQuery.sizeOf(context).height * _collapsed;
    final camera = await map.cameraForCoordinatesPadding(
      coordinates,
      mapbox.CameraOptions(),
      mapbox.MbxEdgeInsets(top: 100, left: 48, right: 48, bottom: sheetHeightPx + 24),
      null,
      null,
    );
    if (!mounted) return;
    await map.flyTo(camera, mapbox.MapAnimationOptions(duration: 700));
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

  /// Tapping a toll/fuel row in the sheet centres the map on that stop.
  Future<void> _focusStop(TripCoordinate coordinate) async {
    final map = _map;
    if (map == null) return;
    // Drop the sheet back to its collapsed size first, otherwise the point
    // we are flying to lands behind it.
    if (_sheetController.isAttached && _sheetController.size > _collapsed) {
      await _sheetController.animateTo(
        _collapsed,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      if (!mounted) return;
    }
    await map.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(coordinate.lng, coordinate.lat),
        ),
        zoom: 14,
      ),
      mapbox.MapAnimationOptions(duration: 700),
    );
  }

  void _onAlternativeSelected(String alternativeId) {
    context.read<RouteOverviewBloc>().add(RouteOverviewAlternativeSelected(alternativeId));
  }

  void _onStart() {
    context.read<RouteOverviewBloc>().add(const RouteOverviewStartPressed());
  }

  void _onRetry() {
    context.read<RouteOverviewBloc>().add(
          RouteOverviewStarted(
            originFallbackLabel: 'trips.origin'.tr(),
            destinationFallbackLabel: 'trips.destination'.tr(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      body: BlocConsumer<RouteOverviewBloc, RouteOverviewState>(
        listenWhen: (p, c) =>
            _renderKey(p) != _renderKey(c) ||
            p.loadStatus != c.loadStatus ||
            p.startTick != c.startTick ||
            p.startStatus != c.startStatus,
        listener: (context, state) {
          _renderRoute(state);
          if (state.startStatus == RouteOverviewStartStatus.failure &&
              state.startError.isNotEmpty) {
            AppSnackBar.showError(context, state.startError);
          }
          final session = state.session;
          if (session != null && state.startTick > 0) {
            context.push(
              Pages.drivingMode,
              extra: DrivingModeArgs(
                session: session,
                destinationLabel: state.destination?.fieldLabel ?? '',
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            fit: StackFit.expand,
            children: [
              mapbox.MapWidget(
                key: const ValueKey('routeOverviewMap'),
                styleUri: mapbox.MapboxStyles.STANDARD,
                onMapCreated: _onMapCreated,
                cameraOptions: mapbox.CameraOptions(
                  center: mapbox.Point(coordinates: _initialCenter),
                  zoom: 10.0,
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
              ValueListenableBuilder<double>(
                valueListenable: _sheetExtent,
                builder: (context, extent, child) {
                  final size = MediaQuery.sizeOf(context);
                  final topInset = MediaQuery.paddingOf(context).top;
                  // Riding the sheet all the way to _expanded would push the
                  // pair off the top on shorter screens, so stop them just
                  // below the status bar.
                  final ceiling = math.max(
                    16.0,
                    size.height - topInset - 16 - _zoomStackHeight,
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
                  ],
                ),
              ),
              _RouteSheet(
                controller: _sheetController,
                collapsed: _collapsed,
                half: _half,
                expanded: _expanded,
                state: state,
                onAlternativeSelected: _onAlternativeSelected,
                onStopSelected: _focusStop,
                onStart: _onStart,
                onRetry: _onRetry,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RouteSheet extends StatelessWidget {
  const _RouteSheet({
    required this.controller,
    required this.collapsed,
    required this.half,
    required this.expanded,
    required this.state,
    required this.onAlternativeSelected,
    required this.onStopSelected,
    required this.onStart,
    required this.onRetry,
  });

  final DraggableScrollableController controller;
  final double collapsed;
  final double half;
  final double expanded;
  final RouteOverviewState state;
  final ValueChanged<String> onAlternativeSelected;
  final ValueChanged<TripCoordinate> onStopSelected;
  final VoidCallback onStart;
  final VoidCallback onRetry;

  /// Translates a drag on the pinned header into a sheet resize. Deltas are
  /// in pixels; the controller works in fractions of the screen height.
  void _onHeaderDrag(BuildContext context, DragUpdateDetails details) {
    if (!controller.isAttached) return;
    final height = MediaQuery.sizeOf(context).height;
    if (height <= 0) return;
    controller.jumpTo(
      (controller.size - details.primaryDelta! / height).clamp(collapsed, expanded),
    );
  }

  /// Matches the sheet's own `snapSizes` once the drag is released.
  void _snapHeader() {
    if (!controller.isAttached) return;
    final current = controller.size;
    var nearest = collapsed;
    for (final target in [collapsed, half, expanded]) {
      if ((target - current).abs() < (nearest - current).abs()) nearest = target;
    }
    controller.animateTo(
      nearest,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  /// The sheet content proper: a spinner while the history tap's detail is
  /// still in flight, then the waypoint list (or the reason there isn't one).
  Widget _buildBody(ScrollController scrollController) {
    if (state.loadStatus == RouteOverviewLoadStatus.loading) {
      return _centered(
        scrollController,
        const CircularProgressIndicator.adaptive(),
      );
    }
    if (state.loadStatus == RouteOverviewLoadStatus.failure) {
      return _centered(
        scrollController,
        _SheetMessage(
          text: state.loadError.isEmpty
              ? 'common.somethingWentWrong'.tr()
              : state.loadError,
          onRetry: onRetry,
        ),
      );
    }
    if (!state.hasAlternatives) {
      return _centered(
        scrollController,
        _SheetMessage(text: 'routeOverview.noRoutes'.tr()),
      );
    }
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.zero,
      children: [
        _WaypointList(
          origin: state.origin!,
          destination: state.destination!,
          alternative: state.selectedAlternative!,
          onStopSelected: onStopSelected,
        ),
      ],
    );
  }

  /// Centres [child] in the sheet while still handing the sheet's scroll
  /// controller a scrollable, so dragging the body keeps resizing the sheet.
  Widget _centered(ScrollController scrollController, Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }

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
              // The header sits outside the scrollable, so it no longer drags
              // the sheet on its own - DraggableScrollableSheet only resizes
              // from the scrollable wired to its controller. Forward vertical
              // drags by hand so the handle and tabs stay grabbable.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) => _onHeaderDrag(context, details),
                onVerticalDragEnd: (_) => _snapHeader(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    // Pinned: switching alternatives has to stay reachable
                    // however far down the waypoint list the driver scrolls.
                    if (state.isReady && state.hasAlternatives) ...[
                      _AlternativeTabs(
                        trip: state.trip,
                        selectedId: state.selectedAlternativeId,
                        onSelected: onAlternativeSelected,
                      ),
                      Divider(color: AppColor.grey2, height: 1),
                    ],
                  ],
                ),
              ),
              Expanded(child: _buildBody(scrollController)),
              if (state.isReady && state.hasAlternatives)
                _PinnedFooter(
                  alternative: state.selectedAlternative!,
                  loading: state.startStatus == RouteOverviewStartStatus.loading,
                  onStart: onStart,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AlternativeTabs extends StatelessWidget {
  const _AlternativeTabs({
    required this.trip,
    required this.selectedId,
    required this.onSelected,
  });

  final TripModel trip;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    var alternativeIndex = 0;
    final chips = <Widget>[];
    for (final alt in trip.alternatives) {
      final isRecommended = alt.id == trip.recommendedAlternativeId;
      if (!isRecommended) alternativeIndex++;
      final label = isRecommended
          ? 'routeOverview.recommended'.tr()
          : 'routeOverview.alternative'.tr(namedArgs: {'index': '$alternativeIndex'});
      if (chips.isNotEmpty) chips.add(const SizedBox(width: 10));
      chips.add(_AlternativeChip(
        label: label,
        distanceMiles: alt.distanceMiles,
        total: alt.total,
        selected: alt.id == selectedId,
        onTap: () => onSelected(alt.id),
      ));
    }
    // Sized by its content instead of a fixed height: the chip stacks two
    // lines of text, which overflows a hard-coded box as soon as a label
    // wraps or the device text scale is bumped up.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: chips),
    );
  }
}

class _AlternativeChip extends StatelessWidget {
  const _AlternativeChip({
    required this.label,
    required this.distanceMiles,
    required this.total,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final double distanceMiles;
  final TripMoney? total;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColor.kPrimary2Color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColor.kPrimaryColor : AppColor.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              total == null
                  ? '${distanceMiles.toStringAsFixed(0)} mi'
                  : '${distanceMiles.toStringAsFixed(0)} mi • -${total!.formatted}',
              style: TextStyle(fontSize: 11, color: AppColor.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centered message inside the sheet - "no routes", or the load error with a
/// retry for the history flow that fetches its own detail.
class _SheetMessage extends StatelessWidget {
  const _SheetMessage({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColor.grey),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onRetry,
                child: Text('common.retry'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WaypointList extends StatelessWidget {
  const _WaypointList({
    required this.origin,
    required this.destination,
    required this.alternative,
    required this.onStopSelected,
  });

  final PlaceModel origin;
  final PlaceModel destination;
  final TripAlternative alternative;
  final ValueChanged<TripCoordinate> onStopSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EndpointRow(
            icon: AppIcons.tripOrigin,
            title: origin.fieldLabel,
            lineAbove: false,
          ),
          // The toll API returns each marker's name/coordinate/amount but no
          // distance-from-start, so `distanceMiles` stays null and the row
          // drops the "in X mi" segment shown in docs/ui/toll-fuel-list.png.
          // Fuel stops are not in the payload at all - see _StopKind.
          for (final toll in alternative.tollMarkers)
            _StopRow(
              kind: _StopKind.toll,
              title: toll.name,
              distanceMiles: null,
              trailing: toll.amount == null ? null : '-${toll.amount!.formatted}',
              onTap: () => onStopSelected(toll.coordinate),
            ),
          _EndpointRow(
            icon: AppIcons.tripDestination,
            title: destination.fieldLabel,
            lineBelow: false,
          ),
        ],
      ),
    );
  }
}

/// A stop on the route. `fuel` is wired up because the design calls for it,
/// but nothing feeds it yet: the toll API exposes fuel only as one aggregate
/// cost per alternative, never as a list of stations.
enum _StopKind {
  toll(AppIcons.tollLeading, 'routeOverview.toll'),
  // Kept so the row renders correctly the moment the API starts returning
  // fuel stops; remove if that never lands.
  // ignore: unused_field
  fuel(AppIcons.fuelLeading, 'routeOverview.fuelStation');

  const _StopKind(this.icon, this.badgeKey);

  final String icon;
  final String badgeKey;
}

/// The origin / destination rows: no badge, no price, just the emphasized
/// address against the timeline.
class _EndpointRow extends StatelessWidget {
  const _EndpointRow({
    required this.icon,
    required this.title,
    this.lineAbove = true,
    this.lineBelow = true,
  });

  final String icon;
  final String title;
  final bool lineAbove;
  final bool lineBelow;

  @override
  Widget build(BuildContext context) {
    return _TimelineRow(
      icon: icon,
      iconSize: 18,
      tintIcon: true,
      lineAbove: lineAbove,
      lineBelow: lineBelow,
      child: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColor.black,
        ),
      ),
    );
  }
}

/// A toll gantry or fuel station: address, then a badge + optional distance,
/// a dashed leader filling the gap, and the price on the right.
class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.kind,
    required this.title,
    required this.distanceMiles,
    required this.trailing,
    required this.onTap,
  });

  final _StopKind kind;
  final String title;
  final double? distanceMiles;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The sheet paints its own white background, so the splash needs a local
    // Material above it to be visible at all.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: _TimelineRow(
          icon: kind.icon,
          iconSize: 16,
          lineAbove: true,
          lineBelow: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColor.black,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.lightBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      kind.badgeKey.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColor.black,
                      ),
                    ),
                  ),
                  if (distanceMiles != null) ...[
                    const SizedBox(width: 10),
                    Text(
                      'routeOverview.inMiles'.tr(
                        namedArgs: {'miles': distanceMiles!.toStringAsFixed(0)},
                      ),
                      style: TextStyle(fontSize: 13, color: AppColor.grey),
                    ),
                  ],
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: _DashedLeader(),
                    ),
                  ),
                  if (trailing != null)
                    Text(
                      trailing!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColor.black,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row of the timeline: a leading icon centred on the row with the dashed
/// connector running through the gutter to the rows above and below.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.icon,
    required this.iconSize,
    required this.lineAbove,
    required this.lineBelow,
    required this.child,
    this.tintIcon = false,
  });

  final String icon;
  final double iconSize;
  final bool lineAbove;
  final bool lineBelow;
  final bool tintIcon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight lets the gutter stretch to whatever the content column
    // ends up being, so the connector meets the next row's dash exactly.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: CustomPaint(
              painter: _ConnectorPainter(
                above: lineAbove,
                below: lineBelow,
                gap: iconSize / 2 + 4,
              ),
              child: Center(
                child: SvgPicture.asset(
                  icon,
                  width: iconSize,
                  height: iconSize,
                  colorFilter: tintIcon
                      ? ColorFilter.mode(AppColor.darkGrey, BlendMode.srcIn)
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// The dashed vertical connector, drawn in the gutter behind the row icon.
class _ConnectorPainter extends CustomPainter {
  const _ConnectorPainter({
    required this.above,
    required this.below,
    required this.gap,
  });

  final bool above;
  final bool below;

  /// Half-height of the hole left around the icon.
  final double gap;

  static const double _dash = 5;
  static const double _space = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColor.lightGreyBlue
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final x = size.width / 2;
    final centre = size.height / 2;
    if (above) _dashes(canvas, paint, x, centre - gap, 0);
    if (below) _dashes(canvas, paint, x, centre + gap, size.height);
  }

  /// Walks from `start` towards `end` in either direction.
  void _dashes(Canvas canvas, Paint paint, double x, double start, double end) {
    final step = end > start ? _dash + _space : -(_dash + _space);
    final dash = end > start ? _dash : -_dash;
    var y = start;
    while (end > start ? y < end : y > end) {
      final to = end > start ? (y + dash).clamp(y, end) : (y + dash).clamp(end, y);
      canvas.drawLine(Offset(x, y), Offset(x, to), paint);
      y += step;
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      old.above != above || old.below != below || old.gap != gap;
}

/// The dashed rule that fills the space between a stop's badge and its price.
class _DashedLeader extends StatelessWidget {
  const _DashedLeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 1, child: CustomPaint(painter: _LeaderPainter()));
  }
}

class _LeaderPainter extends CustomPainter {
  static const double _dash = 4;
  static const double _space = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColor.grey2
      ..strokeWidth = 1;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += _dash + _space) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + _dash).clamp(0, size.width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LeaderPainter oldDelegate) => false;
}

/// The fuel / toll / mile stats and the start button (docs/ui/over_view_bottom.svg).
/// Pinned below the scrollable part of the sheet, with the upward shadow the
/// design uses to separate it from the content that scrolls under it.
class _PinnedFooter extends StatelessWidget {
  const _PinnedFooter({
    required this.alternative,
    required this.loading,
    required this.onStart,
  });

  final TripAlternative alternative;
  final bool loading;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _ServiceStat(
                    icon: AppIcons.routeFuel,
                    label: 'routeOverview.fuel'.tr(),
                    value: alternative.fuel == null
                        ? '-'
                        : '-${alternative.fuel!.formatted}',
                  ),
                  _ServiceStat(
                    icon: AppIcons.routeToll,
                    label: 'routeOverview.toll'.tr(),
                    value: alternative.toll == null
                        ? '-'
                        : '-${alternative.toll!.formatted}',
                  ),
                  _ServiceStat(
                    icon: AppIcons.routeMile,
                    label: 'routeOverview.mile'.tr(),
                    value: '${alternative.distanceMiles.toStringAsFixed(0)} mi',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  onPressed: loading ? null : onStart,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColor.kPrimaryColor,
                    disabledBackgroundColor: AppColor.kPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          'routeOverview.start'.tr(),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceStat extends StatelessWidget {
  const _ServiceStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    // Each stat takes an equal share of the row rather than sizing to its
    // text: the localized labels are much longer than the English ones
    // ("Пошлина" vs "Toll") and would otherwise overflow the row.
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(icon, width: 34, height: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: AppColor.grey),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColor.black,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: AppColor.black),
        ),
      ),
    );
  }
}

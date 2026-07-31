import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/utils/polyline_codec.dart';
import 'package:taxi_app/src/core/utils/route_progress.dart';
import 'package:taxi_app/src/features/trips/data/model/navigation_session_model.dart';
import 'package:taxi_app/src/features/trips/data/model/trip_model.dart';
import 'package:taxi_app/src/features/trips/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:taxi_app/src/features/trips/presentation/controllers/driving_camera.dart';
import 'package:taxi_app/src/features/trips/presentation/controllers/driving_session.dart';
import 'package:taxi_app/src/features/trips/presentation/controllers/marker_animator.dart';
import 'package:taxi_app/src/features/trips/presentation/utils/marker_icon.dart';

/// The session created in Route Overview plus the human-readable destination
/// label (the session itself only carries raw lat/lng, per
/// `NavigationSessionModel.destination`).
class DrivingModeArgs {
  final NavigationSessionModel session;
  final String destinationLabel;

  const DrivingModeArgs({required this.session, required this.destinationLabel});
}

/// Driving Mode (docs/ui/9.png): live turn-by-turn following of the session
/// started in Route Overview.
///
/// Motion runs on two clocks, deliberately:
/// - **60 fps** - [MarkerAnimator] interpolates the vehicle between GPS fixes
///   and drives both the marker annotation and the camera. Never touches bloc
///   state, so no widget rebuilds at frame rate.
/// - **Per GPS fix** - [DrivingSession] publishes telemetry, which repaints the
///   driven/remaining polyline split and the distance readout.
///
/// The bloc stays on its own slower clock (a throttled server report every 5s)
/// and remains authoritative for progress, arrival and reroute geometry.
class DrivingModePage extends StatefulWidget {
  const DrivingModePage({super.key, required this.args});

  final DrivingModeArgs args;

  @override
  State<DrivingModePage> createState() => _DrivingModePageState();
}

/// Shared with route overview - the same pin marks the trip's end on both maps.
const String _finishMarkerAsset = 'assets/icons/finish_marker.svg';

class _DrivingModePageState extends State<DrivingModePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  /// Bounds for the zoom buttons. Below 8 the route stops being legible at
  /// driving pitch; above 19 Mapbox runs out of tiles on most styles.
  static const double _minZoom = 8.0;
  static const double _maxZoom = 19.0;

  /// Per-frame fraction of the remaining zoom difference the camera closes, so
  /// a button tap eases in over a few frames rather than jumping a whole level.
  static const double _zoomGlide = 0.25;

  /// Minimum change before the bottom bar is rebuilt, so a 9 Hz fix stream at
  /// highway speed doesn't drive 9 setState calls a second for a readout that
  /// only shows tenths of a mile.
  static const double _distanceRepaintM = 10;

  mapbox.MapboxMap? _map;
  mapbox.PolylineAnnotationManager? _lines;
  mapbox.PointAnnotationManager? _markers;

  /// The puck lives in its own manager because icon pitch/rotation alignment
  /// are layer properties, not per-annotation ones. The puck must lie flat on
  /// the map plane; the destination and toll pins must stay billboarded
  /// upright. One manager cannot do both.
  mapbox.PointAnnotationManager? _driverMarkers;

  mapbox.PolylineAnnotation? _drivenLine;
  mapbox.PolylineAnnotation? _remainingLine;
  mapbox.PointAnnotation? _driverMarker;

  MarkerAnimator? _animator;
  DrivingSession? _session;

  /// Keyed on the polyline, not the session id: a reroute returns the *same*
  /// session with new geometry, so an id check would never re-render it.
  String? _renderedPolyline;

  bool _cameraFollowing = true;
  double _cameraBearing = 0;

  /// Zoom the camera is actually rendering at, eased toward [_targetZoom] on
  /// the marker tick.
  double _currentZoom = DrivingCamera.defaultZoom;

  /// Zoom the buttons have asked for.
  double _targetZoom = DrivingCamera.defaultZoom;

  /// Annotation and camera updates cross a platform channel, so a frame is
  /// skipped while the previous call is still in flight rather than queueing
  /// work the channel can't drain. Dropping frames degrades gracefully;
  /// queueing them compounds into lag.
  bool _markerBusy = false;
  bool _cameraBusy = false;
  bool _splitBusy = false;

  DrivingTelemetry? _telemetry;
  String? _sessionError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final session = widget.args.session;
    final last = session.lastLocation;
    final initial = last != null
        ? LatLng(last.latitude, last.longitude)
        : LatLng(session.destination.lat, session.destination.lng);

    final animator = MarkerAnimator(vsync: this, initial: initial);
    animator.snapshot.addListener(_onMarkerTick);
    _animator = animator;

    final bloc = context.read<NavigationBloc>();
    final session_ = DrivingSession(
      locationService: bloc.locationService,
      markerAnimator: animator,
      onFix: (fix) {
        if (!mounted) return;
        bloc.add(NavigationLocationUpdated(fix));
      },
      onOffRoute: (origin) {
        if (!mounted) return;
        bloc.add(NavigationRerouteRequested(
          TripCoordinate(lat: origin.latitude, lng: origin.longitude),
        ));
      },
    );
    session_.telemetry.addListener(_onTelemetry);
    _session = session_;

    bloc.add(const NavigationStarted());
    _startSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Session first: it stops the GPS stream that feeds the animator.
    _session?.telemetry.removeListener(_onTelemetry);
    _session?.dispose();
    _animator?.snapshot.removeListener(_onMarkerTick);
    _animator?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<NavigationBloc>().add(const NavigationResumeRequested());
    }
  }

  Future<void> _startSession() async {
    try {
      await _session?.start();
      if (mounted && _sessionError != null) {
        setState(() => _sessionError = null);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sessionError = _readableError(e));
    }
  }

  static String _readableError(Object e) {
    final text = e.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }

  // ── Map setup ──────────────────────────────────────────────────────────

  void _onMapCreated(mapbox.MapboxMap map) {
    _map = map;
    map.style.setProjection(
      mapbox.StyleProjection(name: mapbox.StyleProjectionName.mercator),
    );
    map.scaleBar.updateSettings(mapbox.ScaleBarSettings(enabled: false));
    map.compass.updateSettings(mapbox.CompassSettings(enabled: false));
    final session = context.read<NavigationBloc>().state.session;
    if (session != null) _renderSession(session);
  }

  Future<void> _renderSession(NavigationSessionModel session) async {
    final map = _map;
    if (map == null || _renderedPolyline == session.route.polyline) return;
    _renderedPolyline = session.route.polyline;

    _lines ??= await map.annotations.createPolylineAnnotationManager();
    _markers ??= await map.annotations.createPointAnnotationManager();
    if (!mounted) return;

    if (_driverMarkers == null) {
      final driverLayer = await map.annotations.createPointAnnotationManager();
      if (!mounted) return;
      // The Mapbox equivalent of Google Maps' `flat: true`, which is what the
      // Quadrix marker uses. MAP alignment lays the icon on the map plane and
      // rotates it with the map, so under the 60 degree driving pitch it
      // foreshortens into the road instead of standing up facing the camera.
      // Without this the puck reads as a sticker pasted on the screen.
      await driverLayer
          .setIconPitchAlignment(mapbox.IconPitchAlignment.MAP);
      if (!mounted) return;
      await driverLayer
          .setIconRotationAlignment(mapbox.IconRotationAlignment.MAP);
      if (!mounted) return;
      // Never let symbol collision hide the vehicle behind a pin or a label.
      await driverLayer.setIconAllowOverlap(true);
      if (!mounted) return;
      await driverLayer.setIconIgnorePlacement(true);
      if (!mounted) return;
      _driverMarkers = driverLayer;
    }

    await _lines!.deleteAll();
    await _markers!.deleteAll();
    await _driverMarkers!.deleteAll();
    if (!mounted) return;
    _drivenLine = null;
    _remainingLine = null;
    _driverMarker = null;

    final points = decodePolyline(session.route.polyline);

    // Hand the route to the session before drawing: snapping, off-route
    // detection and the split all key off it.
    _session?.setRoute(points);

    if (points.isNotEmpty) {
      _remainingLine = await _lines!.create(mapbox.PolylineAnnotationOptions(
        geometry: mapbox.LineString(coordinates: _toPositions(points)),
        lineColor: AppColor.kPrimaryColor.toARGB32(),
        lineWidth: 6,
      ));
      if (!mounted) return;

      // Drawn first so it stacks beneath the active route. Seeded degenerate
      // (a single repeated point) and grown as the driver advances.
      _drivenLine = await _lines!.create(mapbox.PolylineAnnotationOptions(
        geometry: mapbox.LineString(
          coordinates: _toPositions([points.first, points.first]),
        ),
        lineColor: AppColor.grey2.toARGB32(),
        lineWidth: 6,
      ));
      if (!mounted) return;
    }

    // finish_marker.svg is the map pin. Not AppIcons.tripDestination, which is
    // the grey trip-planner *field* icon and renders nearly invisible on a map.
    final destinationPng = await rasterizeMarkerSvg(_finishMarkerAsset);
    if (!mounted) return;
    await _markers!.create(mapbox.PointAnnotationOptions(
      geometry: mapbox.Point(
        coordinates:
            mapbox.Position(session.destination.lng, session.destination.lat),
      ),
      image: destinationPng,
      iconSize: 1.7,
      iconAnchor: mapbox.IconAnchor.BOTTOM,
    ));
    if (!mounted) return;

    // Same toll-only marker set as route overview - see route_overview_bloc.dart
    // for why fuel stations have no map pin.
    if (session.routeAlternative.tollMarkers.isNotEmpty) {
      final tollPng = await rasterizeMarkerSvg(AppIcons.tollMarker, height: 72);
      if (!mounted) return;
      for (final toll in session.routeAlternative.tollMarkers) {
        await _markers!.create(mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position(toll.coordinate.lng, toll.coordinate.lat),
          ),
          image: tollPng,
          iconSize: 1.1,
          iconAnchor: mapbox.IconAnchor.BOTTOM,
        ));
        if (!mounted) return;
      }
    }

    // The vehicle puck goes on last so it draws above the route and the pins.
    final snapshot = _animator?.snapshot.value;
    final driverPng = await buildDriverPuck();
    if (!mounted) return;
    _driverMarker = await _driverMarkers!.create(mapbox.PointAnnotationOptions(
      geometry: mapbox.Point(
        coordinates: mapbox.Position(
          snapshot?.position.longitude ?? session.destination.lng,
          snapshot?.position.latitude ?? session.destination.lat,
        ),
      ),
      image: driverPng,
      // The puck bitmap is mostly shadow padding - only ~62% of it is the disc
      // - so it is scaled up beyond the pins' factor to land at a comparable
      // on-screen footprint, since their art fills their bitmap.
      iconSize: 1.85,
      iconRotate: snapshot?.bearingDeg ?? 0,
      // Centre-anchored and rotating in place: the puck marks a point, unlike
      // the destination/toll pins which sit on their tip.
      iconAnchor: mapbox.IconAnchor.CENTER,
    ));
  }

  static List<mapbox.Position> _toPositions(List<LatLng> points) =>
      points.map((p) => mapbox.Position(p.longitude, p.latitude)).toList();

  // ── 60 fps path: marker + camera ───────────────────────────────────────

  void _onMarkerTick() {
    final snapshot = _animator?.snapshot.value;
    if (snapshot == null) return;
    _updateDriverMarker(snapshot);
    if (_cameraFollowing) _updateCamera(snapshot);
  }

  Future<void> _updateDriverMarker(MarkerSnapshot snapshot) async {
    final markers = _driverMarkers;
    final marker = _driverMarker;
    if (markers == null || marker == null || _markerBusy) return;

    _markerBusy = true;
    marker.geometry = mapbox.Point(
      coordinates: mapbox.Position(
        snapshot.position.longitude,
        snapshot.position.latitude,
      ),
    );
    marker.iconRotate = snapshot.bearingDeg;
    try {
      await markers.update(marker);
    } catch (_) {
      // The manager can be torn down mid-flight on navigation away.
    } finally {
      _markerBusy = false;
    }
  }

  Future<void> _updateCamera(MarkerSnapshot snapshot) async {
    final map = _map;
    if (map == null || _cameraBusy) return;

    // Low-pass the heading so the map swings smoothly instead of snapping at
    // every route waypoint. Alpha scales with speed: faster driving needs a
    // snappier camera to keep up through highway curves, while a slow crawl
    // wants heavy damping so GPS-derived heading noise doesn't wobble the map.
    final speedMps = _telemetry?.speedMps ?? 0;
    final alpha = (0.12 + (speedMps / 30) * 0.13).clamp(0.12, 0.25);
    _cameraBearing = MarkerAnimator.interpolateBearing(
      _cameraBearing,
      snapshot.bearingDeg,
      alpha,
    );

    // Ease toward the button target, then settle exactly so the comparison
    // can't oscillate on floating-point dust.
    if ((_currentZoom - _targetZoom).abs() > 0.01) {
      _currentZoom += (_targetZoom - _currentZoom) * _zoomGlide;
    } else {
      _currentZoom = _targetZoom;
    }

    _cameraBusy = true;
    try {
      await map.setCamera(DrivingCamera.optionsFor(
        position: snapshot.position,
        smoothedBearing: _cameraBearing,
        zoom: _currentZoom,
      ));
    } catch (_) {
      // Ignore: the map can be disposed between frames.
    } finally {
      _cameraBusy = false;
    }
  }

  void _zoomBy(double delta) {
    final next = (_targetZoom + delta).clamp(_minZoom, _maxZoom);
    if (next == _targetZoom) return;
    _targetZoom = next;

    if (!_cameraFollowing) {
      // Free camera: zoom in place and leave the centre where the driver put
      // it. Eased, because nothing else is animating this view.
      _currentZoom = next;
      _map?.easeTo(
        mapbox.CameraOptions(zoom: next),
        mapbox.MapAnimationOptions(duration: 200),
      );
      return;
    }

    // Following: the marker tick normally glides the zoom in. But the tick
    // only fires while the marker is animating, so parked at a light a tap
    // would otherwise do nothing until the vehicle moved again - apply it
    // directly in that case.
    final snapshot = _animator?.snapshot.value;
    if (_animator?.isAnimating != true && snapshot != null) {
      _currentZoom = next;
      _updateCamera(snapshot);
    }
  }

  // ── Per-fix path: polyline split + readout ─────────────────────────────

  void _onTelemetry() {
    final telemetry = _session?.telemetry.value;
    if (telemetry == null || !mounted) return;

    final split = telemetry.split;
    if (split != null) _applySplit(split);

    // Repaint the readout only when it would visibly change.
    final previous = _telemetry;
    final changed = previous == null ||
        (previous.remainingRouteMeters - telemetry.remainingRouteMeters).abs() >=
            _distanceRepaintM ||
        previous.isOnRoute != telemetry.isOnRoute;
    if (changed) setState(() => _telemetry = telemetry);
  }

  Future<void> _applySplit(RouteSplit split) async {
    final lines = _lines;
    final driven = _drivenLine;
    final remaining = _remainingLine;
    if (lines == null || driven == null || remaining == null || _splitBusy) {
      return;
    }
    if (split.driven.length < 2 || split.remaining.length < 2) return;

    _splitBusy = true;
    driven.geometry = mapbox.LineString(coordinates: _toPositions(split.driven));
    remaining.geometry =
        mapbox.LineString(coordinates: _toPositions(split.remaining));
    try {
      await lines.update(driven);
      await lines.update(remaining);
    } catch (_) {
      // Manager torn down mid-flight.
    } finally {
      _splitBusy = false;
    }
  }

  // ── User actions ───────────────────────────────────────────────────────

  void _onRecenter() {
    setState(() => _cameraFollowing = true);
    final snapshot = _animator?.snapshot.value;
    if (snapshot != null) _updateCamera(snapshot);
  }

  void _onUserPan(mapbox.MapContentGestureContext _) {
    if (!_cameraFollowing) return;
    setState(() => _cameraFollowing = false);
  }

  /// Cancelling ends the trip server-side and pops the screen, so it is
  /// confirmed first - it is a single tap away from the driver's thumb while
  /// the vehicle is moving, and there is no undo.
  Future<void> _onCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColor.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'drivingMode.cancelTitle'.tr(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColor.black,
          ),
        ),
        content: Text(
          'drivingMode.cancelMessage'.tr(),
          style: TextStyle(fontSize: 13, color: AppColor.black),
        ),
        actions: [
          // Dismiss is the low-emphasis default: the safe outcome should be
          // the easy one to pick by accident.
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'drivingMode.cancelDismiss'.tr(),
              style: TextStyle(color: AppColor.black, fontSize: 13),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColor.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'drivingMode.cancelConfirm'.tr(),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    context.read<NavigationBloc>().add(const NavigationCancelPressed());
  }

  /// Distance still to drive. Prefers the locally-snapped figure, which
  /// updates every fix; falls back to the server's, which lands every 5s and
  /// is the only source while off-route.
  int _remainingMeters(NavigationSessionModel session) {
    final telemetry = _telemetry;
    if (telemetry != null && telemetry.isOnRoute) {
      return telemetry.remainingRouteMeters.round();
    }
    return session.progress.remainingDistanceMeters;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      body: BlocConsumer<NavigationBloc, NavigationState>(
        listenWhen: (p, c) =>
            p.session?.route.polyline != c.session?.route.polyline ||
            p.status != c.status,
        listener: (context, state) {
          final session = state.session;
          if (session != null) _renderSession(session);
          if (state.status == NavigationPageStatus.closed) {
            context.pop();
          }
        },
        builder: (context, state) {
          final session = state.session ?? widget.args.session;
          final error = _sessionError ??
              (state.status == NavigationPageStatus.error
                  ? state.errorMessage
                  : null);

          return Stack(
            fit: StackFit.expand,
            children: [
              mapbox.MapWidget(
                key: const ValueKey('drivingModeMap'),
                styleUri: mapbox.MapboxStyles.STANDARD,
                onMapCreated: _onMapCreated,
                onScrollListener: _onUserPan,
                cameraOptions: mapbox.CameraOptions(
                  center: mapbox.Point(
                    coordinates: mapbox.Position(
                      session.destination.lng,
                      session.destination.lat,
                    ),
                  ),
                  zoom: 14.0,
                ),
              ),
              if (state.status == NavigationPageStatus.loading)
                const Center(child: CircularProgressIndicator.adaptive()),
              if (error != null)
                _ErrorOverlay(
                  message: error,
                  onBack: () => context.pop(),
                  onRetry: () {
                    if (_sessionError != null) {
                      _startSession();
                    } else {
                      context
                          .read<NavigationBloc>()
                          .add(const NavigationResumeRequested());
                    }
                  },
                ),
              if (error == null && session.route.maneuvers.isNotEmpty)
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 12,
                  left: 16,
                  right: 76,
                  child: _ManeuverBanner(
                    maneuver:
                        session.progress.nextManeuver ?? session.route.maneuvers.first,
                    rerouting: state.status == NavigationPageStatus.rerouting,
                  ),
                ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 12,
                left: 16,
                child: session.route.maneuvers.isEmpty
                    ? _CircleButton(
                        iconData: Icons.arrow_back,
                        onTap: () => context.pop(),
                      )
                    : const SizedBox.shrink(),
              ),
              // Ending the trip is destructive, so it sits top-right - far from
              // the recenter/zoom cluster the driver reaches for under way, and
              // in the slot the maneuver banner already reserves.
              Positioned(
                top: MediaQuery.paddingOf(context).top + 12,
                right: 16,
                child: _CircleButton(
                  iconData: Icons.close_rounded,
                  onTap: _onCancel,
                  iconColor: AppColor.red,
                  tooltip: 'drivingMode.cancel'.tr(),
                ),
              ),
              // Controls and the bar share one bottom-anchored column, so the
              // buttons sit a fixed gap above the bar however tall it grows.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16, bottom: 12),
                      child: _MapControls(
                        onZoomIn: () => _zoomBy(1),
                        onZoomOut: () => _zoomBy(-1),
                        onRecenter: _onRecenter,
                        // Emphasised while the camera is detached, so the way
                        // back to follow-mode is obvious after a manual pan.
                        recenterHighlighted: !_cameraFollowing,
                      ),
                    ),
                    _BottomBar(
                      destinationLabel: widget.args.destinationLabel,
                      progress: session.progress,
                      remainingMeters: _remainingMeters(session),
                      speedMps: _telemetry?.speedMps,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Bottom-right control stack: zoom in, zoom out, then recenter.
///
/// Recenter sits lowest as the closest button to the driver's thumb - it is
/// the one pressed under way, after a glance-and-pan pulls the camera off the
/// vehicle.
class _MapControls extends StatelessWidget {
  const _MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRecenter,
    required this.recenterHighlighted,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRecenter;
  final bool recenterHighlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The two zoom buttons read as one control, so they are joined into a
        // single rounded slab with a hairline divider rather than floating
        // apart like the recenter button.
        Material(
          color: AppColor.white,
          elevation: 3,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ZoomButton(
                icon: Icons.add_rounded,
                onTap: onZoomIn,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              Container(width: 24, height: 1, color: AppColor.grey2),
              _ZoomButton(
                icon: Icons.remove_rounded,
                onTap: onZoomOut,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _CircleButton(
          icon: AppIcons.gpsRecenter,
          onTap: onRecenter,
          highlighted: recenterHighlighted,
        ),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.onTap,
    required this.borderRadius,
  });

  final IconData icon;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: borderRadius,
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, size: 22, color: AppColor.black),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({
    required this.message,
    required this.onBack,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(140),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.isEmpty ? 'common.somethingWentWrong'.tr() : message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColor.black),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(onPressed: onBack, child: Text('common.back'.tr())),
                const SizedBox(width: 8),
                FilledButton(onPressed: onRetry, child: Text('common.retry'.tr())),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ManeuverBanner extends StatelessWidget {
  const _ManeuverBanner({required this.maneuver, required this.rerouting});

  final ManeuverModel maneuver;
  final bool rerouting;

  IconData get _icon {
    return switch (maneuver.modifier) {
      'left' => Icons.turn_left,
      'sharp left' => Icons.turn_sharp_left,
      'slight left' => Icons.turn_slight_left,
      'right' => Icons.turn_right,
      'sharp right' => Icons.turn_sharp_right,
      'slight right' => Icons.turn_slight_right,
      'uturn' => Icons.u_turn_left,
      _ => Icons.straight,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColor.kPrimaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(_icon, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _distanceLabel(maneuver.distanceMeters),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  rerouting ? 'drivingMode.rerouting'.tr() : maneuver.instruction,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _distanceLabel(int meters) {
    final miles = meters / 1609.344;
    return '${miles.toStringAsFixed(miles >= 10 ? 0 : 1)} mi';
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.destinationLabel,
    required this.progress,
    required this.remainingMeters,
    required this.speedMps,
  });

  final String destinationLabel;
  final NavigationProgress progress;
  final int remainingMeters;

  /// Null until the first fix arrives.
  final double? speedMps;

  @override
  Widget build(BuildContext context) {
    final speed = speedMps;
    // No Align here: the parent column is already bottom-anchored, and an
    // Align inside it would stretch the bar to fill the screen.
    return SafeArea(
      top: false,
      child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(28), blurRadius: 16),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cancel used to sit here; it now lives as an icon button in the
              // top-right, so the label gets the full width.
              Text(
                destinationLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColor.black,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _distance(remainingMeters),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColor.black,
                    ),
                  ),
                  if (speed != null)
                    Text(
                      '${(speed * 2.23694).round()} mph',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColor.black,
                      ),
                    ),
                  Text(
                    _duration(progress.remainingDurationSeconds),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColor.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (progress.percent / 100).clamp(0, 1),
                  minHeight: 5,
                  backgroundColor: AppColor.grey2,
                  valueColor: AlwaysStoppedAnimation(AppColor.kPrimaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _distance(int meters) {
    final miles = meters / 1609.344;
    return '${miles.toStringAsFixed(miles >= 100 ? 0 : 1)} mi';
  }

  static String _duration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours == 0) return '${minutes}m';
    return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    this.icon,
    this.iconData,
    required this.onTap,
    this.highlighted = false,
    this.iconColor,
    this.tooltip,
  });

  /// SVG asset path, mutually exclusive with [iconData].
  final String? icon;
  final IconData? iconData;
  final VoidCallback onTap;
  final bool highlighted;

  /// Overrides the default icon tint. Ignored while [highlighted], which
  /// inverts the button to a filled treatment.
  final Color? iconColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: highlighted ? AppColor.kPrimaryColor : AppColor.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: icon != null
                ? SvgPicture.asset(
                    icon!,
                    width: 20,
                    height: 20,
                    colorFilter: highlighted
                        ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                        : null,
                  )
                : Icon(
                    iconData,
                    size: 20,
                    color: highlighted
                        ? Colors.white
                        : (iconColor ?? AppColor.black),
                  ),
          ),
        ),
      ),
    );

    final label = tooltip;
    if (label == null) return button;
    return Tooltip(message: label, child: button);
  }
}

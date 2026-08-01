import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/core/constants/color/app_icons.dart';
import 'package:taxi_app/core/utils/geo_math.dart';
import 'package:taxi_app/core/utils/polyline_codec.dart';
import 'package:taxi_app/core/utils/unit_format.dart';
import 'package:taxi_app/features/trips/data/model/navigation_session_model.dart';
import 'package:taxi_app/features/trips/data/model/trip_model.dart';
import 'package:taxi_app/features/trips/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:taxi_app/features/trips/presentation/controllers/driving_camera.dart';
import 'package:taxi_app/features/trips/presentation/controllers/driving_session.dart';
import 'package:taxi_app/features/trips/presentation/controllers/marker_animator.dart';
import 'package:taxi_app/features/trips/presentation/utils/marker_icon.dart';

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

  // The active route is drawn as four polylines, ported from Quadrix:
  //
  //   driven-main  │ driven-conn │ remaining-conn │ remaining-main
  //    static O(1) │ 2 pts, 60fps│  2 pts, 60fps  │   static O(1)
  //
  // The two connectors meet at the vehicle and are the only geometry rebuilt
  // per frame - 4 coordinates across the platform channel. The mains carry the
  // bulk of the route and are rebuilt only when the vehicle crosses into the
  // next segment, which is well under 1 Hz.
  mapbox.PolylineAnnotation? _drivenMain;
  mapbox.PolylineAnnotation? _drivenConn;
  mapbox.PolylineAnnotation? _remainingConn;
  mapbox.PolylineAnnotation? _remainingMain;
  mapbox.PointAnnotation? _driverMarker;

  /// Segment the split currently sits on. -1 forces a rebuild of the mains.
  int _splitSegIdx = -1;

  /// Identity of the route the cached split belongs to, so a reroute
  /// invalidates it.
  List<LatLng>? _splitRouteIdentity;

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

  /// Annotation and camera updates cross a platform channel, so a whole frame
  /// is skipped while the previous one is still in flight rather than queueing
  /// work the channel can't drain. Dropping frames degrades gracefully;
  /// queueing them compounds into lag.
  ///
  /// One guard for the entire frame, not one per update: the marker, the split
  /// connectors and the camera all describe the same instant, and letting them
  /// land independently tears - the seam under the vehicle drifts away from
  /// the puck it is supposed to be welded to.
  bool _frameBusy = false;

  /// Set while an animated recenter is running, so the per-frame camera writes
  /// don't cancel it mid-flight.
  bool _recentering = false;

  /// Guards the async camera read used to adopt a pinch-zoom.
  bool _zoomAdoptBusy = false;

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
    _drivenMain = null;
    _drivenConn = null;
    _remainingConn = null;
    _remainingMain = null;
    _driverMarker = null;
    // Force the split cache to rebuild against the new geometry.
    _splitSegIdx = -1;
    _splitRouteIdentity = null;

    final points = decodePolyline(session.route.polyline);

    // Hand the route to the session before drawing: snapping, off-route
    // detection and the split all key off it.
    _session?.setRoute(points);

    if (points.length >= 2) {
      // The session densifies the route on install, so split against the same
      // point list the snapping and telemetry use - not the raw decode.
      final routePoints = _session?.routePoints ?? points;
      final zero = _toPositions([routePoints.first, routePoints.first]);
      final drivenColor = AppColor.grey2.toARGB32();
      final remainingColor = AppColor.kPrimaryColor.toARGB32();
      const width = 6.0;

      // Creation order is draw order: the mains go down first, then the two
      // connectors, so the short seam segments sit on top where they meet.
      _drivenMain = await _lines!.create(mapbox.PolylineAnnotationOptions(
        geometry: mapbox.LineString(coordinates: zero),
        lineColor: drivenColor,
        lineWidth: width,
      ));
      if (!mounted) return;

      // Seeded with the whole route: before the first fix nothing is driven.
      _remainingMain = await _lines!.create(mapbox.PolylineAnnotationOptions(
        geometry: mapbox.LineString(coordinates: _toPositions(routePoints)),
        lineColor: remainingColor,
        lineWidth: width,
      ));
      if (!mounted) return;

      // Connectors start collapsed to a point, which renders as nothing under
      // the default butt cap, and come alive on the first frame with telemetry.
      _drivenConn = await _lines!.create(mapbox.PolylineAnnotationOptions(
        geometry: mapbox.LineString(coordinates: zero),
        lineColor: drivenColor,
        lineWidth: width,
      ));
      if (!mounted) return;

      _remainingConn = await _lines!.create(mapbox.PolylineAnnotationOptions(
        geometry: mapbox.LineString(coordinates: zero),
        lineColor: remainingColor,
        lineWidth: width,
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
    if (snapshot == null || _frameBusy) return;
    _pumpFrame(snapshot);
  }

  /// One frame of driving output: puck, split seam, camera - in that order,
  /// under a single in-flight guard so they can never land out of step.
  Future<void> _pumpFrame(MarkerSnapshot snapshot) async {
    _frameBusy = true;
    try {
      await _updateDriverMarker(snapshot);
      await _updateSplit(snapshot.position);
      if (_cameraFollowing && !_recentering) await _updateCamera(snapshot);
    } catch (_) {
      // Managers and the map can be torn down mid-frame on navigation away.
    } finally {
      _frameBusy = false;
    }
  }

  Future<void> _updateDriverMarker(MarkerSnapshot snapshot) async {
    final markers = _driverMarkers;
    final marker = _driverMarker;
    if (markers == null || marker == null) return;

    marker.geometry = mapbox.Point(
      coordinates: mapbox.Position(
        snapshot.position.longitude,
        snapshot.position.latitude,
      ),
    );
    marker.iconRotate = snapshot.bearingDeg;
    await markers.update(marker);
  }

  /// Splits the route at the *animated marker*, not at the last GPS fix.
  ///
  /// This is the fix for the seam jumping: the marker glides at 60 fps between
  /// fixes, so splitting at fix rate left the boundary a whole second behind
  /// it, snapping forward each time a fix landed. Ported from Quadrix's
  /// `_buildPolylines`.
  Future<void> _updateSplit(LatLng markerPos) async {
    final lines = _lines;
    final session = _session;
    final drivenConn = _drivenConn;
    final remainingConn = _remainingConn;
    if (lines == null ||
        session == null ||
        drivenConn == null ||
        remainingConn == null) {
      return;
    }

    final telemetry = session.telemetry.value;
    final points = session.routePoints;
    final total = session.routeLengthMeters;

    // Only split mid-route. At either end there is nothing to divide, and a
    // degenerate split would put both connectors on top of each other.
    final canSplit = telemetry != null &&
        points.length >= 2 &&
        telemetry.travelledRouteMeters > 0 &&
        telemetry.travelledRouteMeters < total &&
        telemetry.segmentIndex < points.length - 1;
    if (!canSplit) return;

    // While on-route, follow the marker. Once off-route, freeze the seam at
    // the last confirmed on-route point so it can't slide down a parallel road.
    final splitPos = telemetry.isOnRoute || telemetry.routeSplitPoint == null
        ? markerPos
        : telemetry.routeSplitPoint!;

    // Fast path: check the cached segment still contains the split (one
    // segmentT call, a couple of multiplies) before paying for a scan.
    final int segIdx;
    if (!identical(_splitRouteIdentity, points) || _splitSegIdx < 0) {
      segIdx = _findSegment(splitPos, points, telemetry.segmentIndex);
    } else {
      final t = segmentT(
        splitPos,
        points[_splitSegIdx],
        points[_splitSegIdx + 1],
      );
      segIdx = (t >= 0 && t <= 1)
          ? _splitSegIdx
          : _findSegment(splitPos, points, telemetry.segmentIndex);
    }

    // Rebuild the bulk polylines only when the vehicle crosses a segment.
    if (segIdx != _splitSegIdx || !identical(_splitRouteIdentity, points)) {
      _splitSegIdx = segIdx;
      _splitRouteIdentity = points;

      final drivenMain = _drivenMain;
      if (drivenMain != null) {
        final pts = points.sublist(0, segIdx + 1);
        drivenMain.geometry = mapbox.LineString(
          // A one-point line is invalid; collapse it onto the start instead.
          coordinates: _toPositions(
            pts.length >= 2 ? pts : [points.first, points.first],
          ),
        );
        await lines.update(drivenMain);
      }

      final remainingMain = _remainingMain;
      if (remainingMain != null) {
        final pts = points.sublist(segIdx + 1);
        remainingMain.geometry = mapbox.LineString(
          coordinates: _toPositions(
            pts.length >= 2 ? pts : [points.last, points.last],
          ),
        );
        await lines.update(remainingMain);
      }
    }

    // The only geometry that crosses the channel every frame: 4 coordinates.
    drivenConn.geometry = mapbox.LineString(
      coordinates: _toPositions([points[segIdx], splitPos]),
    );
    await lines.update(drivenConn);

    remainingConn.geometry = mapbox.LineString(
      coordinates: _toPositions([splitPos, points[segIdx + 1]]),
    );
    await lines.update(remainingConn);
  }

  /// Index of the route segment closest to [pos] by perpendicular distance.
  ///
  /// Scans at most 16 segments ending at [gpsSegIdx], so cost is O(1) whatever
  /// the route length - the marker is never far from where the last fix put it.
  int _findSegment(LatLng pos, List<LatLng> points, int gpsSegIdx) {
    final lo = (gpsSegIdx - 15).clamp(0, points.length - 2);
    final hi = gpsSegIdx.clamp(0, points.length - 2);
    int best = hi;
    double minDist = double.infinity;
    for (int k = lo; k <= hi; k++) {
      final d = haversine(pos, projectOnSegment(pos, points[k], points[k + 1]));
      if (d < minDist) {
        minDist = d;
        best = k;
      }
    }
    return best;
  }

  Future<void> _updateCamera(MarkerSnapshot snapshot) async {
    final map = _map;
    if (map == null) return;

    // Low-pass the heading so the map swings smoothly instead of snapping at
    // every route waypoint. Alpha scales with speed: faster driving needs a
    // snappier camera to keep up through highway curves, while a slow crawl
    // wants heavy damping so GPS-derived heading noise doesn't wobble the map.
    final speedMps = _session?.telemetry.value?.speedMps ?? 0;
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

    await map.setCamera(DrivingCamera.optionsFor(
      position: snapshot.position,
      smoothedBearing: _cameraBearing,
      zoom: _currentZoom,
    ));
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
    // directly in that case, through the same guard the pump uses so the two
    // can't write the camera at once.
    final snapshot = _animator?.snapshot.value;
    if (_animator?.isAnimating != true &&
        snapshot != null &&
        !_frameBusy &&
        !_recentering) {
      _currentZoom = next;
      _frameBusy = true;
      _updateCamera(snapshot)
          .catchError((_) {})
          .whenComplete(() => _frameBusy = false);
    }
  }

  // ── Per-fix path: polyline split + readout ─────────────────────────────

  /// Telemetry now only feeds the readout. The polyline split moved onto the
  /// 60 fps frame pump, where it can track the marker instead of lagging it.
  void _onTelemetry() {
    final telemetry = _session?.telemetry.value;
    if (telemetry == null || !mounted) return;

    // Repaint the readout only when it would visibly change.
    final previous = _telemetry;
    final changed = previous == null ||
        (previous.remainingRouteMeters - telemetry.remainingRouteMeters).abs() >=
            _distanceRepaintM ||
        previous.isOnRoute != telemetry.isOnRoute;
    if (changed) setState(() => _telemetry = telemetry);
  }

  // ── User actions ───────────────────────────────────────────────────────

  /// Restores the whole driving camera, not just the centre.
  ///
  /// Recentring position alone left the driver looking at their vehicle
  /// through whatever zoom and pitch they had panned away to. Quadrix's
  /// recenter re-applies target, zoom, tilt and bearing together, and resets
  /// the smoothed bearing first so the next frame doesn't spin in from a
  /// stale value.
  Future<void> _onRecenter() async {
    final snapshot = _animator?.snapshot.value;
    setState(() => _cameraFollowing = true);
    final map = _map;
    if (snapshot == null || map == null) return;

    _cameraBearing = snapshot.bearingDeg;
    _targetZoom = DrivingCamera.defaultZoom;
    _currentZoom = DrivingCamera.defaultZoom;

    // Animated, so the driver can see where the view travelled from. The frame
    // pump is held off meanwhile - its per-frame setCamera would cancel the
    // ease on the very next tick.
    _recentering = true;
    try {
      await map.easeTo(
        DrivingCamera.optionsFor(
          position: snapshot.position,
          smoothedBearing: _cameraBearing,
          zoom: _currentZoom,
        ),
        mapbox.MapAnimationOptions(duration: 450),
      );
    } catch (_) {
      // Map torn down mid-animation.
    } finally {
      _recentering = false;
    }
  }

  void _onUserPan(mapbox.MapContentGestureContext _) {
    if (!_cameraFollowing) return;
    setState(() => _cameraFollowing = false);
  }

  /// Adopts a pinch-zoom into the tracked zoom.
  ///
  /// Without this the frame pump writes [_currentZoom] back on the next tick
  /// and the pinch is undone before the driver lifts their fingers.
  Future<void> _onUserZoom(mapbox.MapContentGestureContext _) async {
    final map = _map;
    if (map == null || _zoomAdoptBusy || _recentering) return;
    _zoomAdoptBusy = true;
    try {
      final camera = await map.getCameraState();
      final zoom = camera.zoom.clamp(_minZoom, _maxZoom);
      _currentZoom = zoom;
      _targetZoom = zoom;
    } catch (_) {
      // Map torn down mid-read.
    } finally {
      _zoomAdoptBusy = false;
    }
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
    // The bloc drives the spinner and only closes the screen once the server
    // has confirmed - see NavigationPageStatus.cancelling.
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
            p.status != c.status ||
            p.errorMessage != c.errorMessage,
        listener: (context, state) {
          final session = state.session;
          if (session != null) _renderSession(session);

          // A cancel or complete that failed leaves the trip running, so the
          // message goes in a snackbar over the live map rather than an
          // overlay that would hide the road.
          if (state.status == NavigationPageStatus.active &&
              state.errorMessage.isNotEmpty) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  backgroundColor: AppColor.red,
                  content: Text(state.errorMessage),
                ),
              );
          }

          // The trip is over - stop the GPS pipeline immediately rather than
          // waiting for dispose, so nothing more is uploaded and the marker
          // stops chasing a route that no longer applies.
          if (state.isFinished) _session?.stop();

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
                onZoomListener: _onUserZoom,
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
              // Reporting is down but guidance is not: the route, marker and
              // local ETA all keep working off the cached route, so this is an
              // advisory strip rather than an error state.
              if (state.isOffline && !state.isFinished)
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 68,
                  left: 16,
                  right: 16,
                  child: const _OfflineBanner(),
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
                      // Resuming from the Trips card has no place name to
                      // carry over, so fall back to a neutral label.
                      destinationLabel:
                          widget.args.destinationLabel.trim().isEmpty
                              ? 'drivingMode.destination'.tr()
                              : widget.args.destinationLabel,
                      progress: session.progress,
                      remainingMeters: _remainingMeters(session),
                      speedMps: _telemetry?.speedMps,
                    ),
                  ],
                ),
              ),
              // Blocking scrim while cancel/complete is in flight: the driver
              // must not be able to press either twice, and the screen must
              // not close until the server has actually closed the session.
              if (state.isBusy)
                _BusyOverlay(
                  message: state.status == NavigationPageStatus.cancelling
                      ? 'drivingMode.cancelling'.tr()
                      : 'drivingMode.completing'.tr(),
                ),
              if (state.status == NavigationPageStatus.completed)
                _TripCompletedOverlay(
                  session: state.completedSession ?? session,
                  onDone: () => context
                      .read<NavigationBloc>()
                      .add(const NavigationCompletionAcknowledged()),
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
                  // A turn coming up needs tenths far longer than a trip
                  // total does, hence the much lower whole-number threshold.
                  formatMiles(maneuver.distanceMeters, wholeAbove: 10),
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
                    formatMiles(remainingMeters),
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
                    formatDuration(progress.remainingDurationSeconds),
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

/// Advisory strip shown when progress reports are failing.
///
/// Deliberately not an error overlay: guidance continues off the cached route
/// and the locally-snapped position, so the trip is still usable - only the
/// server's view of it is stale.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColor.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'drivingMode.offline'.tr(),
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Blocking scrim for cancel/complete round-trips.
class _BusyOverlay extends StatelessWidget {
  const _BusyOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator.adaptive(),
              const SizedBox(height: 14),
              Text(
                message,
                style: TextStyle(fontSize: 13, color: AppColor.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trip summary shown after `POST .../complete` succeeds.
///
/// Everything here comes from the closed session the API returned, so the
/// figures are the server's record of the trip rather than the phone's
/// running estimate.
class _TripCompletedOverlay extends StatelessWidget {
  const _TripCompletedOverlay({required this.session, required this.onDone});

  final NavigationSessionModel session;
  final VoidCallback onDone;

  /// Wall-clock trip length, preferred over the route's *planned* duration
  /// because it reflects what actually happened. Null until the API reports
  /// both timestamps.
  Duration? get _elapsed {
    final started = session.startedAt;
    final completed = session.completedAt;
    if (started == null || completed == null) return null;
    return completed.difference(started);
  }

  @override
  Widget build(BuildContext context) {
    final route = session.route;
    final toll = session.routeAlternative.toll;

    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColor.kPrimaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 32,
                color: AppColor.kPrimaryColor,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'drivingMode.tripCompleted'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColor.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'drivingMode.tripCompletedMessage'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColor.grey),
            ),
            const SizedBox(height: 18),
            // Only rows the API actually populated are shown - an empty
            // summary is better than one full of zeroes and dashes.
            if (route.distanceMeters > 0)
              _SummaryRow(
                label: 'drivingMode.summaryDistance'.tr(),
                value: formatMiles(route.distanceMeters),
              ),
            if (_elapsed != null)
              _SummaryRow(
                label: 'drivingMode.summaryDuration'.tr(),
                value: formatDuration(_elapsed!.inSeconds),
              ),
            if (toll != null)
              _SummaryRow(
                label: 'drivingMode.summaryToll'.tr(),
                value: toll.formatted,
              ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColor.kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: onDone,
                child: Text('drivingMode.done'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: AppColor.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColor.black,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:taxi_app/src/core/location_service.dart';
import 'package:taxi_app/src/core/utils/geo_math.dart';
import 'package:taxi_app/src/core/utils/kalman_filter.dart';
import 'package:taxi_app/src/core/utils/polyline_codec.dart';
import 'package:taxi_app/src/core/utils/route_progress.dart';
import 'package:taxi_app/src/features/trips/presentation/controllers/marker_animator.dart';

/// Per-fix driving telemetry. Updates at GPS rate (~1 Hz), not at frame rate -
/// the 60 fps marker/camera path reads [MarkerAnimator.snapshot] instead.
typedef DrivingTelemetry = ({
  double speedMps,
  double bearingDeg,

  /// Metres remaining along the planned line, frozen while off-route.
  double remainingRouteMeters,
  double travelledRouteMeters,

  /// Route segment the driver is on.
  int segmentIndex,

  /// True when the fix snapped onto the planned polyline (within
  /// [_snapThresholdM]) and the heading agrees with the route direction.
  bool isOnRoute,

  /// Last position confirmed to be on the planned line. The page splits the
  /// polyline at the *animated marker* while on-route, and freezes it here
  /// once off-route so the trail can't rewind along a parallel road.
  ///
  /// Deliberately a single point rather than the two split lists: recomputing
  /// those per fix allocated two full copies of the route every second, and
  /// the page needs a frame-rate split anyway, which a per-fix one can't give.
  LatLng? routeSplitPoint,
});

/// How far off the polyline the marker still snaps onto the route. Beyond
/// this it shows the smoothed GPS, so the pin doesn't teleport across lanes
/// or a dual carriageway.
const double _snapThresholdM = 15;

/// How far off the line counts as off-route. 55 m catches a city wrong-turn
/// (parallel streets sit ~20-80 m apart) while staying above lane and GPS
/// noise. The strike filter and bearing check guard the rest.
const double _offRouteThresholdM = 55;

/// Consecutive off-route readings required before reporting it. Filters out
/// single GPS spikes.
const int _offRouteStrikesRequired = 3;

/// Minimum seconds between off-route reports, so a long detour doesn't fire
/// a reroute request on every fix.
const int _rerouteDebounceSeconds = 5;

/// Marker tween bounds. The animation duration tracks the real inter-fix
/// delta, clamped to this band so it neither stalls nor sprints.
const Duration _markerTween = Duration(milliseconds: 1000);
const Duration _markerTweenMin = Duration(milliseconds: 800);
const Duration _markerTweenMax = Duration(milliseconds: 1200);

/// Owns the live-driving subsystems: the GPS subscription, the Kalman
/// smoother, route snapping, off-route detection and marker animation.
///
/// Ported from the Quadrix driver app's `controllers/driving_session.dart`.
/// Two deliberate departures from the original:
///
/// 1. **No BLoC coupling.** Quadrix's session called `bloc.add(...)` directly.
///    Here it reports through [onFix] / [onOffRoute] callbacks, matching this
///    repo's callback-carrying event convention and keeping the controller
///    testable without a bloc.
/// 2. **No phase geofencing.** Quadrix auto-advanced a stop's phase on
///    entering a 300 m zone; easy-drive has no phase model, and arrival is
///    decided server-side from `remaining_distance_meters`.
///
/// Lifecycle belongs to the screen, not the bloc: the page builds a session in
/// `initState` and disposes it in `dispose`.
class DrivingSession {
  final LocationService locationService;
  final MarkerAnimator markerAnimator;

  /// Delivers each smoothed fix. The bloc throttles its own server reporting.
  final void Function(Position fix) onFix;

  /// Fired when the driver has been off the planned line for
  /// [_offRouteStrikesRequired] consecutive fixes. Carries the raw position so
  /// the new route starts from where the driver actually is.
  final void Function(LatLng origin) onOffRoute;

  /// Position stream factory - injectable for tests.
  final Stream<Position> Function()? positionStreamBuilder;

  final KalmanFilter _kalman = KalmanFilter();
  final ValueNotifier<DrivingTelemetry?> _telemetry =
      ValueNotifier<DrivingTelemetry?>(null);

  StreamSubscription<Position>? _gpsSub;

  double _currentBearing = 0;
  double _currentSpeed = 0;
  bool _isRunning = false;

  /// The GPS stream is distance-filtered, so a stationary vehicle stops
  /// emitting and the last speed would stick forever. This fires shortly after
  /// the final fix and forces speed to 0 so the readout doesn't lie at a light
  /// or at the destination.
  Timer? _speedDecayTimer;
  static const int _speedDecayMs = 3000;

  int _offRouteStrikes = 0;
  DateTime? _lastRerouteAt;
  bool _wasOnRoute = false;

  /// Timestamp of the previous fix, used to size the marker tween to the real
  /// inter-fix cadence.
  DateTime? _lastFixAt;

  /// Active route, densified once on install.
  List<LatLng> _routePoints = const [];
  CumulativeDistances? _cumulative;

  /// Last confirmed on-route values. Frozen when the driver leaves the line so
  /// the trail and the remaining distance don't advance on a parallel road.
  double _lastRemaining = 0;
  double _lastTravelled = 0;
  int _lastSegIdx = 0;
  LatLng? _lastRouteSplitPoint;

  DrivingSession({
    required this.locationService,
    required this.markerAnimator,
    required this.onFix,
    required this.onOffRoute,
    this.positionStreamBuilder,
  });

  ValueListenable<DrivingTelemetry?> get telemetry => _telemetry;

  bool get isRunning => _isRunning;

  List<LatLng> get routePoints => _routePoints;

  /// Total length of the installed route, in metres. Used by the page to tell
  /// "mid-route" from "at either end", where splitting the line is pointless.
  double get routeLengthMeters => _cumulative?.total ?? 0;

  /// Installs the route the driver is following. Call on session start and on
  /// every reroute; resets the frozen progress so a new leg starts clean.
  ///
  /// [points] should be the raw decoded polyline - densification happens here.
  void setRoute(List<LatLng> points) {
    _routePoints = points.length < 2 ? points : interpolateRoute(points);
    _cumulative = CumulativeDistances.fromPoints(_routePoints);
    _offRouteStrikes = 0;
    _wasOnRoute = false;
    _lastRemaining = 0;
    _lastTravelled = 0;
    _lastSegIdx = 0;
    _lastRouteSplitPoint = null;
  }

  /// Starts streaming GPS and resets per-trip smoothing and strike counters.
  /// Idempotent.
  ///
  /// Throws if location is unusable, so the caller can surface it and revert
  /// the driving UI.
  Future<void> start() async {
    if (_isRunning) return;

    await _ensureLocationReady();

    _isRunning = true;
    _kalman.reset();
    _offRouteStrikes = 0;
    _wasOnRoute = false;
    _lastFixAt = null;

    final stream = positionStreamBuilder?.call() ??
        locationService.watchPosition();
    _gpsSub = stream.listen(
      _onGpsFix,
      onError: (Object _) {
        // Transient stream errors (a dropped fix, a brief permission blip)
        // must not tear down navigation; the next fix recovers.
      },
    );
  }

  /// Confirms location services are on and a usable permission is granted.
  ///
  /// Uses geolocator rather than permission_handler so the authorization
  /// checked matches the plugin that owns the stream. Mixing the two on iOS
  /// produces a false "permanently denied": permission_handler's
  /// `Permission.location` maps to the iOS *Always* tier, which iOS never
  /// grants on a first prompt (it offers "While Using App"), so the request
  /// reports permanentlyDenied even when the driver tapped Allow.
  Future<void> _ensureLocationReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Location is turned off. Enable Location Services to '
          'start driving.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // While-In-Use is enough to start: background updates continue via the
    // iOS location background mode once a fix is streaming.
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return;
    }

    throw Exception(
      permission == LocationPermission.deniedForever
          ? 'Location permission denied. Enable it in Settings.'
          : 'Location permission denied',
    );
  }

  /// Stops the GPS subscription. Safe without a prior [start].
  Future<void> stop() async {
    _isRunning = false;
    _speedDecayTimer?.cancel();
    _speedDecayTimer = null;
    await _gpsSub?.cancel();
    _gpsSub = null;
    markerAnimator.stop();
    // Drop the cadence baseline so the next session's first fix uses the
    // reference duration rather than a stale, oversized delta.
    _lastFixAt = null;
  }

  Future<void> dispose() async {
    await stop();
    _telemetry.dispose();
  }

  void _onGpsFix(Position pos) {
    final now = DateTime.now();
    final raw = LatLng(pos.latitude, pos.longitude);
    final rawSpeed =
        (pos.speed.isNaN || pos.speed < 0) ? _currentSpeed : pos.speed;

    final smoothed = _kalman.filter(
      measurement: raw,
      accuracyM: pos.accuracy,
      time: now,
      speedMps: rawSpeed,
    );

    _currentSpeed = rawSpeed;

    // Restart the decay timer: while fixes keep arriving the speed readout is
    // real. When the vehicle stops, fixes stop too and the timer zeroes it.
    _speedDecayTimer?.cancel();
    _speedDecayTimer =
        Timer(const Duration(milliseconds: _speedDecayMs), _onSpeedDecay);

    if (pos.heading.isFinite && pos.heading >= 0) {
      _currentBearing = pos.heading;
    }

    // Hand the smoothed fix to the bloc for throttled server reporting.
    onFix(pos);

    final points = _routePoints;
    final cumulative = _cumulative;
    LatLng display = smoothed;
    bool snapped = false;
    RouteProgress? routeProgress;

    if (points.length >= 2 && cumulative != null) {
      routeProgress = snapToRoute(smoothed, points, cumulative);
      if (routeProgress != null) {
        final distFromRoute = haversine(smoothed, routeProgress.splitPoint);
        if (distFromRoute <= _snapThresholdM) {
          display = routeProgress.splitPoint;
          snapped = true;
        }

        // Off-route detection runs on the RAW fix, not the smoothed one: the
        // filter lags real divergence by a fix or two, delaying the reroute.
        // The 3-strike filter still rejects single spikes.
        final rawSnap = snapToRoute(raw, points, cumulative);
        final rawOffRouteM = rawSnap != null
            ? haversine(raw, rawSnap.splitPoint)
            : distFromRoute;
        _maybeReportOffRoute(
          raw,
          isOffRoute: rawOffRouteM > _offRouteThresholdM,
        );
      }
    }

    // Match the tween to the ACTUAL inter-fix delta so the animation lands
    // just as the next fix arrives - robust to irregular cadence in a way a
    // distance/speed estimate is not. First fix falls back to the reference.
    final durationMs = _lastFixAt == null
        ? _markerTween.inMilliseconds
        : now.difference(_lastFixAt!).inMilliseconds.clamp(
              _markerTweenMin.inMilliseconds,
              _markerTweenMax.inMilliseconds,
            );
    _lastFixAt = now;

    // Reject snapping when the driver is travelling against the route
    // direction (>90 degrees apart) - catches a wrong-way parallel road inside
    // the snap threshold. Only trusted while moving; at rest GPS heading is
    // arbitrary.
    final bearingOk = routeProgress == null ||
        _currentSpeed <= 1.5 ||
        _isBearingCompatible(
          driverBearing: _currentBearing,
          routePoints: points,
          segIdx: routeProgress.segmentIndex,
        );

    final onRoute = snapped && bearingOk;
    final markerNow = markerAnimator.snapshot.value.position;

    if (onRoute && _wasOnRoute && routeProgress != null) {
      // Continuing on-route: follow the road geometry so the marker turns at
      // each waypoint instead of cutting the corner.
      markerAnimator.animateAlongPath(
        path: _extractSubPath(
          points,
          markerNow,
          display,
          routeProgress.segmentIndex,
        ),
        duration: Duration(milliseconds: durationMs),
      );
    } else {
      // Off-route, or just regained the route: animate directly so the marker
      // doesn't sweep through unrelated waypoints on its way back.
      final bearing = onRoute
          ? _currentBearing
          : _pickBearing(
              reportedHeading: pos.heading,
              headingAccuracy: pos.headingAccuracy,
              segmentDist: haversine(markerNow, display),
              from: markerNow,
              to: display,
            );
      markerAnimator.animateTo(
        newPos: display,
        bearingDeg: bearing,
        duration: Duration(milliseconds: durationMs),
      );
    }

    _wasOnRoute = onRoute;
    _currentBearing = markerAnimator.targetBearing;

    _emitTelemetry(
      onRoute: onRoute,
      routeProgress: onRoute ? routeProgress : null,
    );
  }

  /// No fix for [_speedDecayMs] - the vehicle is most likely stationary.
  void _onSpeedDecay() {
    if (!_isRunning) return;
    _currentSpeed = 0;
    _emitTelemetry();
  }

  /// Route sub-path from the marker's current position [from] to the new
  /// display position [to] (which lies on segment [toSegIdx]), including the
  /// intermediate waypoints so the marker follows road curves.
  List<LatLng> _extractSubPath(
    List<LatLng> points,
    LatLng from,
    LatLng to,
    int toSegIdx,
  ) {
    // Walk backward from toSegIdx to find the segment [from] sits on.
    int fromSegIdx = toSegIdx.clamp(0, points.length - 2);
    while (fromSegIdx > 0 &&
        segmentT(from, points[fromSegIdx], points[fromSegIdx + 1]) < 0) {
      fromSegIdx--;
    }

    if (fromSegIdx >= toSegIdx) return [from, to];

    final path = <LatLng>[from];
    for (int i = fromSegIdx + 1; i <= toSegIdx; i++) {
      path.add(points[i]);
    }
    path.add(to);
    return path;
  }

  /// True when the driver's heading and the route direction at [segIdx] differ
  /// by less than 90 degrees.
  bool _isBearingCompatible({
    required double driverBearing,
    required List<LatLng> routePoints,
    required int segIdx,
  }) {
    if (segIdx >= routePoints.length - 1) return true;
    final routeBearing =
        bearingBetween(routePoints[segIdx], routePoints[segIdx + 1]);
    return bearingDelta(routeBearing, driverBearing).abs() < 90;
  }

  /// Best bearing for a direct (off-route) animation. GPS heading wins while
  /// moving and accurate; otherwise the travelled segment's direction; at rest
  /// the last known heading holds.
  double _pickBearing({
    required double reportedHeading,
    required double headingAccuracy,
    required double segmentDist,
    required LatLng from,
    required LatLng to,
  }) {
    final headingValid = reportedHeading.isFinite &&
        reportedHeading >= 0 &&
        (headingAccuracy.isNaN ||
            (headingAccuracy >= 0 && headingAccuracy < 30));
    if (_currentSpeed > 1.5 && headingValid) return reportedHeading;
    if (segmentDist > 1.5) return bearingBetween(from, to);
    return _currentBearing;
  }

  /// Publishes a telemetry snapshot.
  ///
  /// Progress only advances on a confirmed on-route fix, and never runs
  /// backward - that protects against rejoining the route behind the last
  /// confirmed position (a detour that looped back) or a wrong-way snap.
  void _emitTelemetry({bool onRoute = false, RouteProgress? routeProgress}) {
    if (onRoute &&
        routeProgress != null &&
        routeProgress.travelledMeters >= _lastTravelled) {
      _lastRemaining = routeProgress.remainingMeters;
      _lastTravelled = routeProgress.travelledMeters;
      _lastSegIdx = routeProgress.segmentIndex;
      _lastRouteSplitPoint = routeProgress.splitPoint;
    }

    _telemetry.value = (
      speedMps: _currentSpeed,
      bearingDeg: _currentBearing,
      remainingRouteMeters: _lastRemaining,
      travelledRouteMeters: _lastTravelled,
      segmentIndex: _lastSegIdx,
      isOnRoute: onRoute,
      routeSplitPoint: _lastRouteSplitPoint,
    );
  }

  /// Reports the driver off-route once they've drifted for
  /// [_offRouteStrikesRequired] consecutive fixes, debounced so a long detour
  /// doesn't fire repeatedly.
  void _maybeReportOffRoute(LatLng origin, {required bool isOffRoute}) {
    if (!isOffRoute) {
      _offRouteStrikes = 0;
      return;
    }
    _offRouteStrikes++;
    if (_offRouteStrikes < _offRouteStrikesRequired) return;

    final last = _lastRerouteAt;
    final now = DateTime.now();
    if (last != null &&
        now.difference(last).inSeconds < _rerouteDebounceSeconds) {
      return;
    }
    _offRouteStrikes = 0;
    _lastRerouteAt = now;
    onOffRoute(origin);
  }
}

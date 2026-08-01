import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:taxi_app/core/utils/geo_math.dart';
import 'package:taxi_app/core/utils/polyline_codec.dart';

/// Snapshot of the driver marker's current animated state.
typedef MarkerSnapshot = ({LatLng position, double bearingDeg});

/// Owns the vsync-bound [AnimationController] that interpolates the driver
/// marker between successive GPS fixes.
///
/// Two modes:
/// - **Direct** ([animateTo]): straight A->B with eased bearing. Used when the
///   driver is off-route or no route is loaded.
/// - **Path-following** ([animateAlongPath]): follows the actual route
///   geometry, turning at each waypoint and taking bearing from the segment
///   direction. Removes the "cuts corners" artefact at fix boundaries.
///
/// Ported from the Quadrix driver app's
/// `feature/maps/presentation/controllers/marker_animator.dart`.
class MarkerAnimator {
  final AnimationController _controller;
  final ValueNotifier<MarkerSnapshot> _snapshot;

  // Direct animation state.
  LatLng _animStart;
  LatLng _animEnd;
  double _animStartBearing;
  double _animEndBearing;

  // Path-following state; an empty path means direct mode is active.
  List<LatLng> _path = const [];
  List<double> _pathCumDist = const []; // length == path.length
  List<double> _pathBearings = const []; // length == path.length - 1
  double _pathTotal = 0;

  bool _disposed = false;

  MarkerAnimator({
    required TickerProvider vsync,
    required LatLng initial,
    Duration duration = const Duration(milliseconds: 1000),
  })  : _controller = AnimationController(vsync: vsync, duration: duration),
        _snapshot =
            ValueNotifier<MarkerSnapshot>((position: initial, bearingDeg: 0)),
        _animStart = initial,
        _animEnd = initial,
        _animStartBearing = 0,
        _animEndBearing = 0 {
    _controller.addListener(_onTick);
  }

  ValueListenable<MarkerSnapshot> get snapshot => _snapshot;

  /// True while the controller is running. The page uses this to decide
  /// whether a camera change can ride the existing tick or must be applied
  /// directly (no ticks arrive while the marker is parked).
  bool get isAnimating => !_disposed && _controller.isAnimating;

  /// Bearing at the end of the current animation. [DrivingSession] reads this
  /// to keep its telemetry heading in sync after dispatching an animation.
  double get targetBearing =>
      _path.isNotEmpty ? _pathBearings.last : _animEndBearing;

  /// Straight-line animation to [newPos] with eased bearing rotation.
  void animateTo({
    required LatLng newPos,
    required double bearingDeg,
    Duration? duration,
  }) {
    if (_disposed) return;
    _path = const [];
    _animStart = _snapshot.value.position;
    _animEnd = newPos;
    _animStartBearing = _snapshot.value.bearingDeg;
    _animEndBearing = bearingDeg;
    if (duration != null) _controller.duration = duration;
    _controller.forward(from: 0);
  }

  /// Animates along [path], following its geometry exactly so the marker turns
  /// at each waypoint instead of cutting the corner. The rotation out of the
  /// previous heading is eased over the first segment.
  void animateAlongPath({required List<LatLng> path, Duration? duration}) {
    if (_disposed) return;
    if (path.length < 2) {
      if (path.length == 1) {
        animateTo(
          newPos: path.first,
          bearingDeg: _snapshot.value.bearingDeg,
          duration: duration,
        );
      }
      return;
    }

    _animStartBearing = _snapshot.value.bearingDeg;

    // Cumulative distances and per-segment bearings, computed once per fix
    // rather than per frame.
    final cumDist = List<double>.filled(path.length, 0.0);
    final bearings = List<double>.filled(path.length - 1, 0.0);
    for (int i = 0; i < path.length - 1; i++) {
      cumDist[i + 1] = cumDist[i] + haversine(path[i], path[i + 1]);
      bearings[i] = bearingBetween(path[i], path[i + 1]);
    }

    // A zero-length path has no direction to derive; fall back to direct.
    if (cumDist.last <= 0) {
      animateTo(
        newPos: path.last,
        bearingDeg: _snapshot.value.bearingDeg,
        duration: duration,
      );
      return;
    }

    _path = path;
    _pathCumDist = cumDist;
    _pathBearings = bearings;
    _pathTotal = cumDist.last;

    if (duration != null) _controller.duration = duration;
    _controller.forward(from: 0);
  }

  /// Teleports the marker with no animation.
  void snapTo(LatLng position, {double bearingDeg = 0}) {
    if (_disposed) return;
    _controller.stop();
    _path = const [];
    _animStart = position;
    _animEnd = position;
    _animStartBearing = bearingDeg;
    _animEndBearing = bearingDeg;
    _snapshot.value = (position: position, bearingDeg: bearingDeg);
  }

  void stop() {
    if (_disposed) return;
    _controller.stop();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _controller.removeListener(_onTick);
    _controller.dispose();
    _snapshot.dispose();
  }

  void _onTick() {
    if (_path.length >= 2 && _pathTotal > 0) {
      _tickPath(_controller.value);
    } else {
      _tickDirect(_controller.value);
    }
  }

  void _tickPath(double t) {
    final dist = t * _pathTotal;

    // Linear scan for the segment containing `dist`. Inter-fix paths are 1-3
    // segments in practice, so this is effectively O(1).
    int seg = _pathBearings.length - 1;
    for (int i = 0; i < _pathBearings.length; i++) {
      if (_pathCumDist[i + 1] >= dist) {
        seg = i;
        break;
      }
    }

    final segLen = _pathCumDist[seg + 1] - _pathCumDist[seg];
    final segT = segLen > 0
        ? ((dist - _pathCumDist[seg]) / segLen).clamp(0.0, 1.0)
        : 0.0;

    final a = _path[seg];
    final b = _path[seg + 1];
    final position = LatLng(
      a.latitude + (b.latitude - a.latitude) * segT,
      a.longitude + (b.longitude - a.longitude) * segT,
    );

    // First segment eases out of the previous heading so the marker doesn't
    // snap; later segments hold their segment bearing exactly.
    final segBearing = _pathBearings[seg];
    final bearing = seg == 0
        ? interpolateBearing(
            _animStartBearing, segBearing, _easeOut(math.min(t * 4, 1.0)))
        : segBearing;

    _snapshot.value = (position: position, bearingDeg: bearing);
  }

  void _tickDirect(double t) {
    final lat =
        _animStart.latitude + (_animEnd.latitude - _animStart.latitude) * t;
    final lng =
        _animStart.longitude + (_animEnd.longitude - _animStart.longitude) * t;
    final bearing =
        interpolateBearing(_animStartBearing, _animEndBearing, _easeOut(t));
    _snapshot.value = (position: LatLng(lat, lng), bearingDeg: bearing);
  }

  /// Quadratic ease-out: quick start, gentle settle - how a vehicle finishes
  /// a turn.
  static double _easeOut(double t) => 1 - (1 - t) * (1 - t);

  /// Interpolates between two bearings along the shortest arc, so
  /// 350deg -> 10deg passes through 0deg rather than sweeping back through 180deg.
  static double interpolateBearing(double start, double end, double t) {
    start = start % 360;
    end = end % 360;
    final delta = bearingDelta(end, start);
    final bearing = (start + delta * t) % 360;
    return bearing < 0 ? bearing + 360 : bearing;
  }
}

import 'dart:math' as math;

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:taxi_app/core/utils/geo_math.dart';
import 'package:taxi_app/core/utils/polyline_codec.dart';

/// Stateless holder for the Driving Mode camera geometry.
///
/// Ported from the Quadrix driver app's `controllers/taxi_camera.dart`,
/// adapted from Google Maps to Mapbox: `pitch` replaces `tilt`, and
/// [mapbox.MapboxMap.setCamera] replaces `moveCamera`.
///
/// The caller supplies the smoothed bearing and the tracked zoom, so filtering
/// and user zoom state stay in the page rather than in here.
class DrivingCamera {
  DrivingCamera._();

  /// Tilted view so the road ahead occupies most of the screen.
  static const double pitch = 60.0;

  /// Default zoom when driving starts.
  static const double defaultZoom = 17.5;

  /// Metres ahead of the vehicle the camera target is placed at
  /// [_forwardRefZoom]. Larger shows more road ahead; smaller keeps the marker
  /// nearer the screen centre.
  static const double forwardMeters = 60.0;

  /// The zoom at which [forwardMeters] applies unscaled.
  static const double _forwardRefZoom = 18.5;

  /// Clamps so the marker neither slides off the bottom edge (offset too large
  /// at high zoom) nor sits dead centre (too small at low zoom).
  static const double _forwardMinMeters = 15.0;
  static const double _forwardMaxMeters = 90.0;

  /// Scales the look-ahead offset with zoom so it stays a roughly constant
  /// *fraction of the screen*. A fixed 60 m covers far more screen at zoom 20
  /// than at zoom 15; without this, zooming in pushes the marker off the
  /// bottom edge at pitch 60. Each +1 zoom halves the on-screen metres, so the
  /// offset halves to compensate.
  static double forwardMetersForZoom(double zoom) {
    final scaled = forwardMeters * math.pow(2.0, _forwardRefZoom - zoom);
    return scaled.clamp(_forwardMinMeters, _forwardMaxMeters).toDouble();
  }

  /// Camera options tracking the vehicle at [position].
  ///
  /// [smoothedBearing] should already be low-pass filtered so the map rotates
  /// gradually instead of snapping at every route waypoint.
  static mapbox.CameraOptions optionsFor({
    required LatLng position,
    required double smoothedBearing,
    required double zoom,
  }) {
    final target =
        forwardTarget(position, smoothedBearing, forwardMetersForZoom(zoom));
    return mapbox.CameraOptions(
      center: mapbox.Point(
        coordinates: mapbox.Position(target.longitude, target.latitude),
      ),
      zoom: zoom,
      pitch: pitch,
      bearing: smoothedBearing,
    );
  }

  /// Moves the camera to track the vehicle.
  ///
  /// Uses [mapbox.MapboxMap.setCamera] - NOT `easeTo` - so calls on the marker
  /// tick replace one another instead of stacking hundreds of millisecond-long
  /// animations. Easing belongs to the marker interpolation, not the camera.
  static void update({
    required mapbox.MapboxMap map,
    required LatLng position,
    required double smoothedBearing,
    required double zoom,
  }) {
    map.setCamera(optionsFor(
      position: position,
      smoothedBearing: smoothedBearing,
      zoom: zoom,
    ));
  }
}

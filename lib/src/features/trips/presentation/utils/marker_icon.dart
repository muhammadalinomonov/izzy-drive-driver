import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';

/// Rasterizes an SVG asset into raw PNG bytes for use as a Mapbox
/// `PointAnnotation` image.
///
/// Deliberately NOT `iconImage: 'marker-15'`: Maki sprite names are not
/// guaranteed to exist in the Standard style, and a missing sprite fails
/// silently - no marker, no error. Compositing our own bytes always renders.
///
/// Shared by the trip-planning map (origin/destination pins) and the route
/// overview / driving mode maps (toll markers).
Future<Uint8List> rasterizeMarkerSvg(String asset, {double height = 96}) async {
  final pictureInfo = await vg.loadPicture(SvgAssetLoader(asset), null);
  final scale = height / pictureInfo.size.height;
  final width = pictureInfo.size.width * scale;

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.scale(scale);
  canvas.drawPicture(pictureInfo.picture);

  final image = await recorder.endRecording().toImage(
        width.round(),
        height.round(),
      );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  pictureInfo.picture.dispose();
  return bytes!.buffer.asUint8List();
}

/// Draws the driving-mode vehicle puck: a white disc carrying a coloured
/// direction chevron, over a soft drop shadow.
///
/// Ported from the Quadrix driver app's `MapMarkerIcons.navArrow()`. It is
/// painted rather than shipped as an asset for two reasons: the chevron picks
/// up [AppColor.kPrimaryColor] at runtime, and the shadow needs a real blur
/// that survives rasterisation at any size.
///
/// The chevron's apex points straight up (north), so Mapbox's `iconRotate`
/// turns it to the driver's bearing directly.
Future<Uint8List> buildDriverPuck({double size = 96}) async {
  final s = size;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  // Soft drop shadow, nudged down so the puck reads as floating above the map.
  canvas.drawCircle(
    Offset(s / 2, s / 2 + s * 0.03),
    s * 0.36,
    Paint()
      ..color = Colors.black.withValues(alpha: 0.20)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.073),
  );

  // White backing disc - keeps the chevron legible over any map style.
  canvas.drawCircle(
    Offset(s / 2, s / 2),
    s * 0.37,
    Paint()..color = Colors.white,
  );

  // Direction chevron, apex at top.
  canvas.drawPath(
    Path()
      ..moveTo(s * .50, s * .13)
      ..lineTo(s * .74, s * .70)
      ..lineTo(s * .50, s * .56)
      ..lineTo(s * .26, s * .70)
      ..close(),
    Paint()..color = AppColor.kPrimaryColor,
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(s.round(), s.round());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  image.dispose();
  return bytes!.buffer.asUint8List();
}

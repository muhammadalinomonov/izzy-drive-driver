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

/// Draws the driving-mode vehicle puck: a domed disc carrying a raised
/// direction chevron, over a soft contact shadow.
///
/// Based on the Quadrix driver app's `MapMarkerIcons.navArrow()`, with the
/// flat fills replaced by shading. Quadrix draws a plain white disc and a
/// solid chevron, which is enough there because Google Maps renders it with
/// `flat: true` under a 60 degree tilt and the perspective alone sells the
/// depth. The layer is drawn on the map plane here too, so the same trick
/// applies - but foreshortening flattens a solid fill into a smear, and the
/// gradients below are what keep it reading as a raised object rather than a
/// painted road marking.
///
/// It is painted rather than shipped as an asset because the chevron picks up
/// [AppColor.kPrimaryColor] at runtime and the shadow needs a real blur that
/// survives rasterisation at any size.
///
/// The chevron's apex points straight up (north), so Mapbox's `iconRotate`
/// turns it to the driver's bearing directly. Light is treated as coming from
/// the top-left, matching Material's convention, so every highlight sits
/// up-left and every shadow down-right.
Future<Uint8List> buildDriverPuck({double size = 96}) async {
  final s = size;
  final centre = Offset(s / 2, s / 2);
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  // The disc occupies 62% of the bitmap, not the ~74% Quadrix uses, leaving
  // room for the blurred shadows to fall off inside the bounds. A blur clipped
  // by the bitmap edge shows as a hard grey arc once the icon is on the map.
  const discR = 0.31;

  // Geometry below was authored against Quadrix's 0.37 disc; this scales it
  // about the centre so the chevron keeps its proportions against the smaller
  // disc rather than needing every literal rewritten.
  const k = discR / 0.37;
  Offset p(double x, double y) => Offset(
        s * (0.5 + (x - 0.5) * k),
        s * (0.5 + (y - 0.5) * k),
      );

  // Contact shadow: offset down-right and blurred, so the puck reads as
  // hovering above the road rather than printed on it.
  canvas.drawCircle(
    Offset(centre.dx + s * 0.010, centre.dy + s * 0.038),
    s * (discR - 0.005),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.34)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.045),
  );

  final discRect = Rect.fromCircle(center: centre, radius: s * discR);

  // Domed body. The gradient runs top-left (bright) to bottom-right (shaded),
  // which is what turns a flat circle into a sphere-like cap.
  canvas.drawCircle(
    centre,
    s * discR,
    Paint()
      ..shader = ui.Gradient.linear(
        discRect.topLeft,
        discRect.bottomRight,
        [Colors.white, const Color(0xFFD9DEE3)],
      ),
  );

  // Terminator: a soft inner shadow hugging the lower-right rim, deepening the
  // curve where the dome falls away from the light. Clipped to the disc so the
  // blurred stroke can't bleed outside the silhouette.
  canvas.save();
  canvas.clipPath(Path()..addOval(discRect));
  canvas.drawCircle(
    Offset(centre.dx + s * 0.018, centre.dy + s * 0.022),
    s * (discR - 0.010),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.030
      ..color = Colors.black.withValues(alpha: 0.10)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.018),
  );
  canvas.restore();

  // Crisp outer rim, so the puck keeps a defined edge against pale roads and
  // bright map styles once perspective has squashed it.
  canvas.drawCircle(
    centre,
    s * discR,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.014
      ..color = Colors.black.withValues(alpha: 0.13),
  );

  final chevron = Path()
    ..moveTo(p(.50, .13).dx, p(.50, .13).dy)
    ..lineTo(p(.74, .70).dx, p(.74, .70).dy)
    ..lineTo(p(.50, .56).dx, p(.50, .56).dy)
    ..lineTo(p(.26, .70).dx, p(.26, .70).dy)
    ..close();

  // The chevron's own drop shadow, lifting it off the dome.
  canvas.save();
  canvas.translate(s * 0.010, s * 0.022);
  canvas.drawPath(
    chevron,
    Paint()
      ..color = Colors.black.withValues(alpha: 0.30)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.022),
  );
  canvas.restore();

  // Shaded chevron: lit face up-left, falling to a darker tone down-right.
  final primary = AppColor.kPrimaryColor;
  final chevronRect = chevron.getBounds();
  canvas.drawPath(
    chevron,
    Paint()
      ..shader = ui.Gradient.linear(
        chevronRect.topLeft,
        chevronRect.bottomRight,
        [
          Color.lerp(primary, Colors.white, 0.34)!,
          Color.lerp(primary, Colors.black, 0.26)!,
        ],
      ),
  );

  // Specular highlight along the chevron's leading edge - the single strongest
  // cue that the surface is angled rather than flat.
  canvas.drawPath(
    Path()
      ..moveTo(p(.50, .17).dx, p(.50, .17).dy)
      ..lineTo(p(.50, .53).dx, p(.50, .53).dy)
      ..lineTo(p(.31, .64).dx, p(.31, .64).dy)
      ..close(),
    Paint()..color = Colors.white.withValues(alpha: 0.22),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(s.round(), s.round());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  image.dispose();
  return bytes!.buffer.asUint8List();
}

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';

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

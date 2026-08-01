import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';

/// History/preview map showing a static route between two points with markers.
///
/// - [fromPoint] : mechanic / start location (Mapbox Point with longitude/latitude)
/// - [toPoint]   : order / destination
/// - [routePoints]: optional polyline coordinates as [longitude, latitude] pairs.
///   Empty list → only markers and the camera framing them.
class OrderMapWidget extends StatefulWidget {
  const OrderMapWidget({
    super.key,
    required this.fromPoint,
    required this.toPoint,
    required this.routePoints,
    this.bottomInset = 24,
    this.maxZoom,
  });

  final Point fromPoint;
  final Point toPoint;
  final List<List<double>> routePoints;
  final double bottomInset;
  final double? maxZoom;

  @override
  State<OrderMapWidget> createState() => _OrderMapWidgetState();
}

class _OrderMapWidgetState extends State<OrderMapWidget> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;

  Uint8List? _fromMarker;
  Uint8List? _toMarker;

  late final MbxEdgeInsets _padding = MbxEdgeInsets(
    top: 60,
    left: 40,
    bottom: widget.bottomInset,
    right: 40,
  );

  void _onMapCreated(MapboxMap map) async {
    _mapboxMap = map;
    try {
      _polylineAnnotationManager = await map.annotations.createPolylineAnnotationManager();
      _pointAnnotationManager = await map.annotations.createPointAnnotationManager();

      _fromMarker = (await rootBundle.load('assets/images/from_marker.png')).buffer.asUint8List();
      _toMarker = (await rootBundle.load('assets/images/to_marker.png')).buffer.asUint8List();

      await _drawRoute();
      await _fitBounds();
    } catch (e) {
      debugPrint('OrderMapWidget: $e');
    }
  }

  Future<void> _drawRoute() async {
    if (_polylineAnnotationManager == null || _pointAnnotationManager == null) return;

    if (widget.routePoints.length >= 2) {
      final positions = widget.routePoints.map((p) => Position(p[0], p[1])).toList();
      await _polylineAnnotationManager!.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: positions),
          lineColor: 0xFF2563EB,
          lineWidth: 4.0,
        ),
      );
    }

    await _pointAnnotationManager!.create(
      PointAnnotationOptions(
        geometry: widget.fromPoint,
        image: _fromMarker,
        iconSize: 1.2,
      ),
    );
    await _pointAnnotationManager!.create(
      PointAnnotationOptions(
        geometry: widget.toPoint,
        image: _toMarker,
        iconSize: 1.4,
      ),
    );
  }

  Future<void> _fitBounds() async {
    if (_mapboxMap == null) return;
    final fromLng = widget.fromPoint.coordinates.lng.toDouble();
    final fromLat = widget.fromPoint.coordinates.lat.toDouble();
    final toLng = widget.toPoint.coordinates.lng.toDouble();
    final toLat = widget.toPoint.coordinates.lat.toDouble();

    final bounds = CoordinateBounds(
      southwest: Point(coordinates: Position(min(fromLng, toLng), min(fromLat, toLat))),
      northeast: Point(coordinates: Position(max(fromLng, toLng), max(fromLat, toLat))),
      infiniteBounds: false,
    );

    final camera = await _mapboxMap!.cameraForCoordinateBounds(
      bounds,
      _padding,
      null,
      null,
      widget.maxZoom,
      null,
    );
    await _mapboxMap!.setCamera(camera);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapWidget(
          key: const ValueKey('orderHistoryMap'),
          styleUri: MapboxStyles.MAPBOX_STREETS,
          cameraOptions: CameraOptions(
            center: widget.fromPoint,
            zoom: 13.0,
          ),
          onMapCreated: _onMapCreated,
        ),
        // Top fade so the back-button stays readable
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 90,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColor.white.withValues(alpha: 0.7),
                    AppColor.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

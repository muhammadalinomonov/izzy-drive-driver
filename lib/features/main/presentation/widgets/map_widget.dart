import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mechanic/assets/constants/images.dart';

class OrderMapWidget extends StatefulWidget {
  const OrderMapWidget({super.key});

  @override
  _OrderMapWidgetState createState() => _OrderMapWidgetState();
}

class _OrderMapWidgetState extends State<OrderMapWidget> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  PolylineAnnotationManager? polylineAnnotationManager;

  // Sizning koordinatalaringiz - bu yerga o'zgartiring
  final Point pointA = Point(coordinates: Position(-104.9903, 39.7392)); // Boshlanish nuqtasi
  final Point pointB = Point(coordinates: Position(-74.0059, 40.7128));   // Tugash nuqtasi

  // Route koordinatalari - sizning tayyor route koordinatalaringiz
  final List<List<double>> routeCoordinates = [
    [-104.9903, 39.7392],  // boshlanish
    [-104.8, 39.8],        // oraliq nuqtalar
    [-104.5, 40.1],
    [-103.2, 40.8],
    [-102.1, 41.2],
    [-101.3, 41.1],
    [-100.2, 40.9],
    [-99.1, 40.8],
    [-98.3, 40.7],
    [-97.2, 40.8],
    [-96.1, 40.9],
    [-95.2, 41.0],
    [-94.3, 41.1],
    [-93.1, 40.9],
    [-92.2, 40.8],
    [-91.1, 40.7],
    [-90.2, 40.6],
    [-89.1, 40.5],
    [-88.2, 40.6],
    [-87.1, 40.7],
    [-86.2, 40.8],
    [-85.1, 40.7],
    [-84.2, 40.6],
    [-83.1, 40.5],
    [-82.2, 40.6],
    [-81.1, 40.7],
    [-80.2, 40.8],
    [-79.1, 40.7],
    [-78.2, 40.6],
    [-77.1, 40.5],
    [-76.2, 40.6],
    [-75.1, 40.7],
    [-74.0059, 40.7128],   // tugash
  ];

  void _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    await _initializeManagers();
    await _drawRoute();
    await _addMarkers();
    _fitMapToRoute();
  }

  Future<void> _initializeManagers() async {
    pointAnnotationManager = await mapboxMap!.annotations.createPointAnnotationManager();
    polylineAnnotationManager = await mapboxMap!.annotations.createPolylineAnnotationManager();
  }

  Future<void> _drawRoute() async {
    final List<Position> routePositions = routeCoordinates
        .map((coord) => Position(coord[0], coord[1]))
        .toList();

    await polylineAnnotationManager!.create(
      PolylineAnnotationOptions(
        geometry: LineString(coordinates: routePositions),
        lineColor: Colors.blue.value,
        lineWidth: 4.0,
      ),
    );
  }

  Future<Uint8List> _loadAssetImage(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List();
  }
  Future<void> _addMarkers() async {
    // A markeri (qora doira, oq A harfi)
    await pointAnnotationManager!.create(
      PointAnnotationOptions(
        geometry: pointA,
        image: await _loadAssetImage('assets/images/from_marker.png'),

        // iconImage: await _createMarkerA(),
        iconSize: 1.0,
      ),
    );

    // B markeri (ko'k doira, oq marker icon)
    await pointAnnotationManager!.create(
      PointAnnotationOptions(
        geometry: pointB,
        image: await _loadAssetImage('assets/images/to_marker.png'),
        iconSize: 1.0,
      ),
    );
  }


  void _fitMapToRoute() {
    double minLat = routeCoordinates.map((e) => e[1]).reduce((a, b) => a < b ? a : b);
    double maxLat = routeCoordinates.map((e) => e[1]).reduce((a, b) => a > b ? a : b);
    double minLng = routeCoordinates.map((e) => e[0]).reduce((a, b) => a < b ? a : b);
    double maxLng = routeCoordinates.map((e) => e[0]).reduce((a, b) => a > b ? a : b);

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    mapboxMap?.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(centerLng, centerLat)),
        zoom: 4.0,
        padding: MbxEdgeInsets(top: 50, left: 50, right: 50, bottom: 50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(-90.0, 40.0)),
        zoom: 3.0,
      ),
      styleUri: MapboxStyles.MAPBOX_STREETS,
      onMapCreated: _onMapCreated,
    );
  }
}
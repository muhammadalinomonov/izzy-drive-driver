import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class OrderMapWidget extends StatefulWidget {
  const OrderMapWidget({
    super.key,
    required this.fromPoint,
    required this.toPoint,
    required this.routePoints,
  });

  final Point fromPoint;
  final Point toPoint;
  final List<List<double>> routePoints;

  @override
  _OrderMapWidgetState createState() => _OrderMapWidgetState();
}

class _OrderMapWidgetState extends State<OrderMapWidget> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  PolylineAnnotationManager? polylineAnnotationManager;

  // Sizning koordinatalaringiz - bu yerga o'zgartiring
  late Point pointA ; // Boshlanish nuqtasi
  late Point pointB ; // Tugash nuqtasi

  // Route koordinatalari - sizning tayyor route koordinatalaringiz
  late List<List<double>> routeCoordinates;

  @override
  void initState() {
    super.initState();

    pointA = widget.fromPoint;
    pointB = widget.toPoint;
    routeCoordinates = widget.routePoints;
  }

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
    final List<Position> routePositions = routeCoordinates.map((coord) => Position(coord[0], coord[1])).toList();

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

  void _fitMapToRoute() async{
    // double minLat = routeCoordinates.map((e) => e[1]).reduce((a, b) => a < b ? a : b);
    // double maxLat = routeCoordinates.map((e) => e[1]).reduce((a, b) => a > b ? a : b);
    // double minLng = routeCoordinates.map((e) => e[0]).reduce((a, b) => a < b ? a : b);
    // double maxLng = routeCoordinates.map((e) => e[0]).reduce((a, b) => a > b ? a : b);
    //
    // final centerLat = (minLat + maxLat) / 2;
    // final centerLng = (minLng + maxLng) / 2;


    final padding = EdgeInsets.all(50.0);

    // Camera bounds o'rnatish
    final bounds = CoordinateBounds(
      southwest: pointA,
      northeast: pointB, infiniteBounds: false,
    );

    final cameraOptions =  CameraBoundsOptions(
        bounds: bounds,
        maxZoom: 14.0, // maksimal zoom
        minZoom: 8.0,  // minimal zoom

    );
    mapboxMap?.setBounds(cameraOptions);
    // mapboxMap?.setCamera(
    //   CameraOptions(
    //     center: Point(coordinates: Position(centerLng, centerLat)),
    //     zoom: 4.0,
    //     padding: MbxEdgeInsets(top: 50, left: 50, right: 50, bottom: 50),
    //   ),
    // );
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

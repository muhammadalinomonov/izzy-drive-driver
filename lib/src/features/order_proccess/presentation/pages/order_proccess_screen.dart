import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:http/http.dart' as http;
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_images.dart';
import 'dart:convert';
import '../../../../core/constants/color/app_icons.dart';

// YANGI: Beautiful Radiation Widget
class BeautifulRadiationWidget extends StatefulWidget {
  final bool isVisible;
  final Offset position;

  const BeautifulRadiationWidget({
    Key? key,
    required this.isVisible,
    required this.position,
  }) : super(key: key);

  @override
  State<BeautifulRadiationWidget> createState() => _BeautifulRadiationWidgetState();
}

class _BeautifulRadiationWidgetState extends State<BeautifulRadiationWidget>
    with TickerProviderStateMixin {
  late AnimationController _radiationController;
  late Animation<double> _radiationAnimation;

  @override
  void initState() {
    super.initState();

    // Radiation animation controller
    _radiationController = AnimationController(
      duration: const Duration(seconds: 2), // 2 soniya davomida
      vsync: this,
    );

    _radiationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _radiationController,
      curve: Curves.easeOut,
    ));

    // Start continuous animation
    if (widget.isVisible) {
      _radiationController.repeat();
    }
  }

  @override
  void didUpdateWidget(BeautifulRadiationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isVisible && !oldWidget.isVisible) {
      _radiationController.repeat();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _radiationController.stop();
    }
  }

  @override
  void dispose() {
    _radiationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Positioned(
      left: widget.position.dx - 150, // Center the radiation
      top: widget.position.dy - 150,
      child: AnimatedBuilder(
        animation: _radiationAnimation,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(300, 300), // 300x300 radiation area
            painter: RadiationPainter(_radiationAnimation.value),
          );
        },
      ),
    );
  }
}

// YANGI: Custom Radiation Painter
class RadiationPainter extends CustomPainter {
  final double animationValue;

  RadiationPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Create 4 beautiful radiation waves
    for (int i = 0; i < 4; i++) {
      // Each wave has different timing offset
      double waveOffset = i * 0.25; // 0.0, 0.25, 0.5, 0.75
      double currentWaveProgress = (animationValue + waveOffset) % 1.0;

      // Calculate radius - starts small, grows large
      double minRadius = 20.0;
      double maxRadius = 120.0;
      double currentRadius = minRadius + (currentWaveProgress * (maxRadius - minRadius));

      // Calculate opacity - starts strong, fades out
      double maxOpacity = 0.4 - (i * 0.08); // Each wave slightly more transparent
      double currentOpacity = maxOpacity * (1.0 - currentWaveProgress);

      if (currentOpacity > 0.02) {
        // Main wave circle
        Paint wavePaint = Paint()
          ..color = const Color(0xFF4A90E2).withOpacity(currentOpacity)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(center, currentRadius, wavePaint);

        // Inner glow effect
        if (currentWaveProgress < 0.8) {
          Paint glowPaint = Paint()
            ..color = const Color(0xFF6BA3E8).withOpacity(currentOpacity * 1.5)
            ..style = PaintingStyle.fill;

          canvas.drawCircle(center, currentRadius * 0.7, glowPaint);
        }

        // Outer ring effect
        Paint ringPaint = Paint()
          ..color = const Color(0xFF87CEEB).withOpacity(currentOpacity * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawCircle(center, currentRadius, ringPaint);
      }
    }

    // Central white platform
    Paint platformPaint = Paint()
      ..color = Colors.white.withOpacity(0.95)
      ..style = PaintingStyle.fill;

    Paint platformBorderPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, 18.0, platformPaint);
    canvas.drawCircle(center, 18.0, platformBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint for smooth animation
  }
}

class OrderProccessScreen extends StatefulWidget {
  const OrderProccessScreen({super.key});

  @override
  State<OrderProccessScreen> createState() => _OrderProccessScreenState();
}

class _OrderProccessScreenState extends State<OrderProccessScreen>
    with TickerProviderStateMixin {

  // Map and Mapbox components
  late mapbox.MapboxMap _mapboxMap;
  mapbox.PolylineAnnotationManager? _polylineAnnotationManager;
  mapbox.PointAnnotationManager? _pointAnnotationManager;
  bool _mapReady = false;

  // Position and route data
  mapbox.Position currentPosition = mapbox.Position(69.2047, 41.2806);
  List<mapbox.Position> fullRouteCoordinates = [];
  List<mapbox.Position> completedRoute = [];
  List<mapbox.Position> remainingRoute = [];

  // Driver simulation
  mapbox.Position currentDriverPosition = mapbox.Position(69.2047, 41.2806);
  int currentRouteIndex = 0;
  Timer? _driverMovementTimer;
  Timer? _debounceTimer;

  // State management
  bool isScrolling = false;
  bool isLoading = false;
  bool isDriverMoving = false;
  bool hasArrived = false;

  // YANGI: Radiation position for overlay
  Offset radiationPosition = const Offset(0, 0);

  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Coordinates for PDP Academy and Chilanzar
  final mapbox.Position startPosition = mapbox.Position(69.2047, 41.2806);
  final mapbox.Position endPosition = mapbox.Position(69.2056, 41.2789);

  // Route information
  double estimatedDistance = 1.2;
  int estimatedDuration = 8;
  String estimatedArrivalTime = '01:40-02:00';
  double routeProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeSocketListeners();
  }

  void _initializeAnimations() {
    // Pulse animation for destination marker
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _onMapCreated(mapbox.MapboxMap mapboxMap) async {
    print('Map creation started...');
    _mapboxMap = mapboxMap;

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      _polylineAnnotationManager = await _mapboxMap.annotations.createPolylineAnnotationManager();
      _pointAnnotationManager = await _mapboxMap.annotations.createPointAnnotationManager();

      print('Annotation managers created successfully');

      await _setInitialCamera();

      setState(() {
        _mapReady = true;
      });

      await _fetchAndDrawRoute();

    } catch (e) {
      print('Error in map creation: $e');
      await _drawSimpleRoute();
    }
  }

  Future<void> _setInitialCamera() async {
    try {
      final midpoint = mapbox.Position(
        (startPosition.lng + endPosition.lng) / 2,
        (startPosition.lat + endPosition.lat) / 2,
      );

      await _mapboxMap.setCamera(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: midpoint),
          zoom: 19.0,
          pitch: 0.0,
          bearing: 0.0,
        ),
      );
      print('Initial camera set successfully');
    } catch (e) {
      print('Error setting initial camera: $e');
    }
  }

  Future<void> _fetchAndDrawRoute() async {
    if (!_mapReady || _polylineAnnotationManager == null || _pointAnnotationManager == null) {
      print('Map not ready, drawing simple route');
      await _drawSimpleRoute();
      return;
    }

    const String accessToken = 'pk.eyJ1IjoiYXphbW92IiwiYSI6ImNtY2hzbjFibjB3cHMycm45N2lkaTZnMWQifQ.6stCvz6FLKcLLhiUEW2NFQ';

    final String url = 'https://api.mapbox.com/directions/v5/mapbox/driving/'
        '${startPosition.lng},${startPosition.lat};'
        '${endPosition.lng},${endPosition.lat}'
        '?geometries=geojson'
        '&steps=true'
        '&overview=full'
        '&access_token=$accessToken';

    try {
      print('Fetching route from API...');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'] as List;

          estimatedDistance = (route['distance'] / 1000.0);
          estimatedDuration = (route['duration'] / 60.0).round();

          fullRouteCoordinates = coordinates
              .map((coord) => mapbox.Position(coord[0].toDouble(), coord[1].toDouble()))
              .toList();

          _updateRouteSegments();

          print('Route fetched successfully with ${fullRouteCoordinates.length} points');

          await _drawRouteAndMarkers();

          setState(() {
            estimatedArrivalTime = _calculateArrivalTime(estimatedDuration);
          });

          _startDriverMovement();

        } else {
          print('No routes found in API response');
          await _drawSimpleRoute();
        }
      } else {
        print('Route API error: ${response.statusCode} - ${response.body}');
        await _drawSimpleRoute();
      }
    } catch (e) {
      print('Error fetching route: $e');
      await _drawSimpleRoute();
    }
  }

  Future<void> _drawSimpleRoute() async {
    print('Drawing simple fallback route...');

    fullRouteCoordinates = _generateIntermediatePoints(startPosition, endPosition, 20);

    _updateRouteSegments();

    await _drawRouteAndMarkers();

    setState(() {
      estimatedDistance = 1.2;
      estimatedDuration = 8;
      estimatedArrivalTime = '01:40-02:00';
    });

    _startDriverMovement();
  }

  void _updateRouteSegments() {
    if (fullRouteCoordinates.isEmpty) return;

    if (currentRouteIndex > 0) {
      completedRoute = fullRouteCoordinates.sublist(0, currentRouteIndex + 1);
    } else {
      completedRoute = [fullRouteCoordinates.first];
    }

    if (currentRouteIndex < fullRouteCoordinates.length - 1) {
      remainingRoute = fullRouteCoordinates.sublist(currentRouteIndex);
    } else {
      remainingRoute = [fullRouteCoordinates.last];
    }
  }

  List<mapbox.Position> _generateIntermediatePoints(mapbox.Position start, mapbox.Position end, int numPoints) {
    List<mapbox.Position> points = [];

    for (int i = 0; i <= numPoints; i++) {
      double ratio = i / numPoints;
      double lat = start.lat + (end.lat - start.lat) * ratio;
      double lng = start.lng + (end.lng - start.lng) * ratio;

      double curve = math.sin(ratio * math.pi) * 0.0005;
      lat += curve;
      lng += curve;

      points.add(mapbox.Position(lng, lat));
    }

    return points;
  }

  Future<void> _drawRouteAndMarkers() async {
    if (!_mapReady || fullRouteCoordinates.isEmpty || _polylineAnnotationManager == null || _pointAnnotationManager == null) {
      print('Cannot draw route - map not ready or no coordinates');
      return;
    }

    try {
      await _polylineAnnotationManager?.deleteAll();
      await _pointAnnotationManager?.deleteAll();

      print('Drawing route with completed: ${completedRoute.length}, remaining: ${remainingRoute.length} points');

      // Draw REMAINING route (light blue)
      if (remainingRoute.length > 1) {
        final remainingLineString = mapbox.LineString(coordinates: remainingRoute);

        await _polylineAnnotationManager?.create(
          mapbox.PolylineAnnotationOptions(
            geometry: remainingLineString,
            lineColor: _hexToInt('#000000'),
            lineWidth: 8.0,
            lineOpacity: 0.1,
          ),
        );

        await _polylineAnnotationManager?.create(
          mapbox.PolylineAnnotationOptions(
            geometry: remainingLineString,
            lineColor: _hexToInt('#87CEEB'),
            lineWidth: 5.0,
            lineOpacity: 0.8,
          ),
        );
      }

      // Draw COMPLETED route (dark blue)
      if (completedRoute.length > 1) {
        final completedLineString = mapbox.LineString(coordinates: completedRoute);

        await _polylineAnnotationManager?.create(
          mapbox.PolylineAnnotationOptions(
            geometry: completedLineString,
            lineColor: _hexToInt('#000000'),
            lineWidth: 8.0,
            lineOpacity: 0.2,
          ),
        );

        await _polylineAnnotationManager?.create(
          mapbox.PolylineAnnotationOptions(
            geometry: completedLineString,
            lineColor: _hexToInt('#007AFF'),
            lineWidth: 6.0,
            lineOpacity: 1.0,
          ),
        );
      }

      print('Route lines drawn successfully');

      // YANGI: Update radiation position when arrived
      if (hasArrived) {
        await _updateRadiationPosition();
      }

      final driverIcon = await _createBiggerDriverPersonIcon();
      final destinationIcon = await _createDestinationMarker();

      await _pointAnnotationManager?.createMulti([
        mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(coordinates: currentDriverPosition),
          image: driverIcon,
        ),
        mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(coordinates: endPosition),
          image: destinationIcon,
        ),
      ]);

      print('Markers added successfully');

    } catch (e) {
      print('Error drawing route and markers: $e');
    }
  }

  // YANGI: Update radiation position on screen
  Future<void> _updateRadiationPosition() async {
    if (!_mapReady) return;

    try {
      // Convert map coordinates to screen coordinates
      final screenCoordinate = await _mapboxMap.pixelForCoordinate(
          mapbox.Point(coordinates: currentDriverPosition)
      );

      setState(() {
        radiationPosition = Offset(screenCoordinate.x, screenCoordinate.y);
      });

    } catch (e) {
      print('Error updating radiation position: $e');
      // Fallback to center of screen
      setState(() {
        radiationPosition = Offset(
          MediaQuery.of(context).size.width / 2,
          MediaQuery.of(context).size.height / 2,
        );
      });
    }
  }

  // Create BIGGER driver person icon
  Future<Uint8List> _createBiggerDriverPersonIcon() async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    const double size = 80.0;

    // Draw person shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(size / 2 + 3, size / 2 + 12), size / 2.5, shadowPaint);

    // Draw person body (orange/brown)
    final bodyPaint = Paint()..color = const Color(0xFFFF8C42);
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size / 2, size / 2 + 12), width: 32, height: 40),
      const Radius.circular(16),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Draw person head
    final headPaint = Paint()..color = const Color(0xFFFFDBB5);
    canvas.drawCircle(Offset(size / 2, size / 2 - 8), 12, headPaint);

    // Draw hair
    final hairPaint = Paint()..color = const Color(0xFF4A4A4A);
    canvas.drawCircle(Offset(size / 2, size / 2 - 12), 11, hairPaint);

    // Draw arms
    final armPaint = Paint()
      ..color = const Color(0xFFFFDBB5)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size / 2 - 16, size / 2), Offset(size / 2 - 24, size / 2 + 8), armPaint);
    canvas.drawLine(Offset(size / 2 + 16, size / 2), Offset(size / 2 + 24, size / 2 + 8), armPaint);

    // Draw legs
    final legPaint = Paint()
      ..color = const Color(0xFF2C5F2D)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size / 2 - 8, size / 2 + 24), Offset(size / 2 - 12, size / 2 + 40), legPaint);
    canvas.drawLine(Offset(size / 2 + 8, size / 2 + 24), Offset(size / 2 + 12, size / 2 + 40), legPaint);

    // Draw white outline
    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(bodyRect, outlinePaint);
    canvas.drawCircle(Offset(size / 2, size / 2 - 8), 12, outlinePaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), (size + 15).toInt());
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // Create destination marker
  Future<Uint8List> _createDestinationMarker() async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    const double size = 60.0;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(size / 2 + 3, size / 2 + 3), size / 2.5, shadowPaint);

    final bgPaint = Paint()..color = const Color(0xFF007AFF);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.5, bgPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.5, borderPaint);

    final iconPaint = Paint()..color = Colors.white;

    final pinPath = Path();
    pinPath.moveTo(size / 2, size / 2 - 8);
    pinPath.lineTo(size / 2 - 6, size / 2 + 2);
    pinPath.lineTo(size / 2, size / 2 + 8);
    pinPath.lineTo(size / 2 + 6, size / 2 + 2);
    pinPath.close();
    canvas.drawPath(pinPath, iconPaint);

    canvas.drawCircle(Offset(size / 2, size / 2 - 2), 4, iconPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _startDriverMovement() {
    if (fullRouteCoordinates.isEmpty) {
      print('Cannot start driver movement - no route coordinates');
      return;
    }

    print('Starting driver movement with ${fullRouteCoordinates.length} points');

    setState(() {
      isDriverMoving = true;
    });

    _driverMovementTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _updateDriverPosition();
    });
  }

  void _updateDriverPosition() {
    if (!mounted || fullRouteCoordinates.isEmpty) return;

    if (currentRouteIndex < fullRouteCoordinates.length - 1) {
      setState(() {
        currentRouteIndex++;
        currentDriverPosition = fullRouteCoordinates[currentRouteIndex];
        routeProgress = currentRouteIndex / fullRouteCoordinates.length;
      });

      _updateRouteSegments();

      print('Driver moved to index $currentRouteIndex, progress: ${(routeProgress * 100).toStringAsFixed(1)}%');

      _drawRouteAndMarkers();
      _followDriver();

    } else {
      // YANGI: Driver arrived - start beautiful radiation!
      _driverMovementTimer?.cancel();
      setState(() {
        isDriverMoving = false;
        hasArrived = true;
        routeProgress = 1.0;
      });

      print('Driver has arrived - starting beautiful radiation!');

      // Update radiation position and start animation
      _updateRadiationPosition();
      _drawRouteAndMarkers();
    }
  }

  void _followDriver() {
    if (!mounted || !_mapReady) return;

    try {
      _mapboxMap.setCamera(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: currentDriverPosition),
          zoom: 19.0,
          pitch: 0.0,
          bearing: 0.0,
        ),
      );

      // Update radiation position when camera moves
      if (hasArrived) {
        _updateRadiationPosition();
      }
    } catch (e) {
      print('Error following driver: $e');
    }
  }

  String _calculateArrivalTime(int durationMinutes) {
    final now = DateTime.now();
    final arrival = now.add(Duration(minutes: durationMinutes));
    final endTime = arrival.add(const Duration(minutes: 20));

    return '${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}-${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
  }

  void _initializeSocketListeners() {
    print('Socket listeners initialized');
  }

  int _hexToInt(String hex) {
    String cleanedHex = hex.replaceAll('#', '');
    if (cleanedHex.length == 6) {
      cleanedHex = 'FF$cleanedHex';
    }
    return int.parse(cleanedHex, radix: 16);
  }

  @override
  void dispose() {
    _driverMovementTimer?.cancel();
    _debounceTimer?.cancel();

    _pulseController.dispose();

    _polylineAnnotationManager?.deleteAll();
    _pointAnnotationManager?.deleteAll();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          Container(
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom +
                  (MediaQuery.of(context).size.height * 0.3),
            ),
            child: mapbox.MapWidget(
              key: const ValueKey('beautifulPulseMapWidget'),
              styleUri: mapbox.MapboxStyles.MAPBOX_STREETS,
              onMapCreated: _onMapCreated,
              cameraOptions: mapbox.CameraOptions(
                center: mapbox.Point(
                  coordinates: mapbox.Position(
                    (startPosition.lng + endPosition.lng) / 2,
                    (startPosition.lat + endPosition.lat) / 2,
                  ),
                ),
                pitch: 0.0,
                zoom: 19.0,
                bearing: 0.0,
              ),
              onCameraChangeListener: (cameraChanged) {
                setState(() => isScrolling = true);
                _debounceTimer?.cancel();
                _debounceTimer = Timer(const Duration(milliseconds: 400), () {
                  if (mounted) {
                    setState(() => isScrolling = false);
                    // Update radiation position after camera stops moving
                    if (hasArrived) {
                      _updateRadiationPosition();
                    }
                  }
                });
              },
            ),
          ),

          // YANGI: Beautiful Radiation Overlay
          BeautifulRadiationWidget(
            isVisible: hasArrived,
            position: radiationPosition,
          ),

          // Bottom Sheet - Beautiful arrival state UI
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColor.greyBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 16,
                      color: Colors.black.withOpacity(0.08),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      width: double.infinity,
                      decoration: const ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Text(
                            hasArrived
                                ? 'Usta keldi va yaqin daqiqalarda ishni boshlaydi.'
                                : 'Usta buyurtmani qabul qildi, va siz tomon harakatlanmoqda!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 19,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              height: 1.40,
                              letterSpacing: -0.30,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hasArrived ? 'Tahminiy ish vaqti' : 'Kelish vaqti',
                            style: const TextStyle(
                              color: Color(0xFF6B7073),
                              fontSize: 13.5,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              height: 1.40,
                              letterSpacing: -0.30,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasArrived ? '40 daqiqa' : estimatedArrivalTime,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              height: 1.40,
                              letterSpacing: -0.30,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _stepIcon(AppIcons.rocket, true),
                              _stepLine(),
                              _stepIcon(AppIcons.maploc, hasArrived),
                              _stepLine(),
                              _stepIcon(AppIcons.pair, false),
                              _stepLine(),
                              _stepIcon(AppIcons.finishflag, false),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      width: double.infinity,
                      decoration: const ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 13),
                          const Text(
                            'Master',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              height: 1.40,
                              letterSpacing: -0.30,
                            ),
                          ),
                          const SizedBox(height: 13),
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 26,
                                backgroundImage: NetworkImage(
                                  'https://azamov.me/assets/images//2024-09-26%2015.09.48.jpg',
                                ),
                              ),
                              const SizedBox(width: 11),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Eshonov Fakhriyor',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14.5,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.30,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '10 years experience',
                                      style: TextStyle(
                                        color: Color(0xFF6B7073),
                                        fontSize: 12.5,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: -0.30,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                  backgroundColor: AppColor.greyBg,
                                ),
                                onPressed: () {},
                                child: const Text(
                                  'More',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.30,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 13),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 44),
                      decoration: const ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Spacer(),
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const ShapeDecoration(
                                      color: Color(0xFFEFF2F5),
                                      shape: CircleBorder(),
                                    ),
                                    child: SvgPicture.asset(
                                      AppIcons.call,
                                      height: 30,
                                      width: 30,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  const Text(
                                    'Call',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.30,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const ShapeDecoration(
                                      color: Color(0xFFEFF2F5),
                                      shape: CircleBorder(),
                                    ),
                                    child: SvgPicture.asset(
                                      AppIcons.about,
                                      height: 30,
                                      width: 30,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  const Text(
                                    'Order About',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.30,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const ShapeDecoration(
                                      color: Color(0xFFEFF2F5),
                                      shape: CircleBorder(),
                                    ),
                                    child: SvgPicture.asset(
                                      AppIcons.close,
                                      height: 30,
                                      width: 30,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  const Text(
                                    'Cancel',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.30,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(height: 11),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepIcon(String icon, bool active) {
    return CircleAvatar(
      backgroundColor: active ? AppColor.blueMain : AppColor.greyBg,
      radius: 24,
      child: SvgPicture.asset(
        icon,
        color: active ? AppColor.white : AppColor.black,
      ),
    );
  }

  Widget _stepLine() {
    return Container(width: 40, height: 2, color: const Color(0xffCDD8EA));
  }
}
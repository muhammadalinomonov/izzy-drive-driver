import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/features/home/presentation/screens/main_screen.dart';
import 'package:taxi_app/src/routes/pages.dart';

import '../../data/model/order_accepted.dart';
import '../bloc/orders_bloc.dart';
import '../widgets/beuty_widget.dart';

class OrderProccessScreen extends StatefulWidget {
  const OrderProccessScreen({super.key});

  @override
  State<OrderProccessScreen> createState() => _OrderProccessScreenState();
}

class _OrderProccessScreenState extends State<OrderProccessScreen> with TickerProviderStateMixin {
  late mapbox.MapboxMap _mapboxMap;
  mapbox.PolylineAnnotationManager? _polylineAnnotationManager;
  mapbox.PointAnnotationManager? _pointAnnotationManager;
  bool _mapReady = false;

  List<mapbox.Position> fullRouteCoordinates = [];
  List<mapbox.Position> completedRoute = [];
  List<mapbox.Position> remainingRoute = [];

  mapbox.Position currentDriverPosition = mapbox.Position(69.2047, 41.2806);
  int currentRouteIndex = 0;
  Timer? _driverMovementTimer;
  Timer? _debounceTimer;
  Timer? _searchTimer;
  int _searchSeconds = 0;

  bool isLoading = true;
  bool isScrolling = false;
  bool isDriverMoving = false;
  bool hasArrived = false;

  Offset radiationPosition = const Offset(0, 0);

  mapbox.Position startPosition = mapbox.Position(69.2047, 41.2806);
  mapbox.Position endPosition = mapbox.Position(69.2056, 41.2789);

  double estimatedDistance = 1.2;
  int estimatedDuration = 8;
  String estimatedArrivalTime = '';

  // Mechanic info from socket
  String mechanicName = 'Eshonov Fakhriyor';
  String mechanicPhone = '+998916624222';
  String? mechanicPhoto;

  @override
  void initState() {
    super.initState();
    _startSearchTimer();
    context.read<OrdersBloc>().add(ConnectToWebSocketEvent());
  }

  void _startSearchTimer() {
    _searchSeconds = 0;
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && isLoading) {
        setState(() => _searchSeconds++);
        if (_searchSeconds >= 30) {
          _searchTimer?.cancel();
        }
      }
    });
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
      setState(() => _mapReady = true);
    } catch (e) {
      print('Error in map creation: $e');
    }
  }

  Future<void> _setInitialCamera() async {
    try {
      final midpoint = mapbox.Position(
        (startPosition.lng + endPosition.lng) / 2,
        (startPosition.lat + endPosition.lat) / 2,
      );
      await _mapboxMap.setCamera(
        mapbox.CameraOptions(center: mapbox.Point(coordinates: midpoint), zoom: 15.5, pitch: 0.0, bearing: 0.0),
      );
      print('Initial camera set successfully');
    } catch (e) {
      print('Error setting initial camera: $e');
    }
  }

  void _processOrderAcceptedData(OrderAccepted orderAccepted) {
    if (!_mapReady || _polylineAnnotationManager == null || _pointAnnotationManager == null) {
      print('Map not ready');
      return;
    }

    try {
      // Update positions from socket data
      startPosition = mapbox.Position(orderAccepted.maps.startPoint.lng, orderAccepted.maps.startPoint.lat);

      endPosition = mapbox.Position(orderAccepted.maps.endPoint.lng, orderAccepted.maps.endPoint.lat);

      // Convert route points to mapbox positions
      final route = orderAccepted.maps.route.map((point) {
        return mapbox.Position(point.lng, point.lat);
      }).toList();

      if (route.isNotEmpty) {
        fullRouteCoordinates = route;
        currentDriverPosition = route.first; // Driver starts at first route point
        currentRouteIndex = 0;

        // Update estimates from socket data
        estimatedDistance = orderAccepted.maps.distanceKm;
        estimatedDuration = orderAccepted.maps.durationMin.round();
        estimatedArrivalTime = _calculateArrivalTime(estimatedDuration);

        // Update mechanic info
        mechanicPhone = orderAccepted.mechanicPhone;
        mechanicPhoto = orderAccepted.mechanicPhoto;

        _updateRouteSegments();
        _drawRouteAndMarkers();
        _startDriverMovement();

        // Update camera to show full route
        _setInitialCamera();
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      _searchTimer?.cancel();
    } catch (e) {
      print('Error processing order accepted data: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
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

  Future<void> _drawRouteAndMarkers() async {
    if (!_mapReady ||
        fullRouteCoordinates.isEmpty ||
        _polylineAnnotationManager == null ||
        _pointAnnotationManager == null ||
        isLoading) {
      print('Cannot draw route - map not ready or loading');
      return;
    }
    try {
      await _polylineAnnotationManager?.deleteAll();
      await _pointAnnotationManager?.deleteAll();
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
      if (hasArrived) await _updateRadiationPosition();
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
    } catch (e) {
      print('Error drawing route and markers: $e');
    }
  }

  Future<void> _updateRadiationPosition() async {
    if (!_mapReady || isScrolling) return;
    try {
      final screenCoordinate = await _mapboxMap.pixelForCoordinate(mapbox.Point(coordinates: currentDriverPosition));
      if (mounted) setState(() => radiationPosition = Offset(screenCoordinate.x, screenCoordinate.y));
    } catch (e) {
      print('Error updating radiation position: $e');
      if (mounted)
        setState(
          () =>
              radiationPosition = Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2),
        );
    }
  }

  Future<Uint8List> _createBiggerDriverPersonIcon() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const double size = 80.0;
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);
    canvas.drawCircle(Offset(size / 2 + 3, size / 2 + 12), size / 2.5, shadowPaint);
    final bodyPaint = Paint()..color = const Color(0xFFFF8C42);
    final bodyRect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromCenter(center: Offset(size / 2, size / 2 + 12), width: 32, height: 40),
      const ui.Radius.circular(16),
    );
    canvas.drawRRect(bodyRect, bodyPaint);
    final headPaint = Paint()..color = const Color(0xFFFFDBB5);
    canvas.drawCircle(Offset(size / 2, size / 2 - 8), 12, headPaint);
    final hairPaint = Paint()..color = const Color(0xFF4A4A4A);
    canvas.drawCircle(Offset(size / 2, size / 2 - 12), 11, hairPaint);
    final armPaint = Paint()
      ..color = const Color(0xFFFFDBB5)
      ..strokeWidth = 6
      ..strokeCap = ui.StrokeCap.round;
    canvas.drawLine(Offset(size / 2 - 16, size / 2), Offset(size / 2 - 24, size / 2 + 8), armPaint);
    canvas.drawLine(Offset(size / 2 + 16, size / 2), Offset(size / 2 + 24, size / 2 + 8), armPaint);
    final legPaint = Paint()
      ..color = const Color(0xFF2C5F2D)
      ..strokeWidth = 8
      ..strokeCap = ui.StrokeCap.round;
    canvas.drawLine(Offset(size / 2 - 8, size / 2 + 24), Offset(size / 2 - 12, size / 2 + 40), legPaint);
    canvas.drawLine(Offset(size / 2 + 8, size / 2 + 24), Offset(size / 2 + 12, size / 2 + 40), legPaint);
    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(bodyRect, outlinePaint);
    canvas.drawCircle(Offset(size / 2, size / 2 - 8), 12, outlinePaint);
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), (size + 15).toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _createDestinationMarker() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const double size = 60.0;
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);
    canvas.drawCircle(Offset(size / 2 + 3, size / 2 + 3), size / 2.5, shadowPaint);
    final bgPaint = Paint()..color = const Color(0xFF007AFF);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.5, bgPaint);
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.5, borderPaint);
    final iconPaint = Paint()..color = Colors.white;
    final pinPath = ui.Path();
    pinPath.moveTo(size / 2, size / 2 - 8);
    pinPath.lineTo(size / 2 - 6, size / 2 + 2);
    pinPath.lineTo(size / 2, size / 2 + 8);
    pinPath.lineTo(size / 2 + 6, size / 2 + 2);
    pinPath.close();
    canvas.drawPath(pinPath, iconPaint);
    canvas.drawCircle(Offset(size / 2, size / 2 - 2), 4, iconPaint);
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _startDriverMovement() {
    if (fullRouteCoordinates.isEmpty) return;
    setState(() => isDriverMoving = true);
    _driverMovementTimer = Timer.periodic(const Duration(seconds: 3), (timer) => _updateDriverPosition());
  }

  void _updateDriverPosition() {
    if (!mounted || fullRouteCoordinates.isEmpty) return;
    if (currentRouteIndex < fullRouteCoordinates.length - 1) {
      setState(() {
        currentRouteIndex++;
        currentDriverPosition = fullRouteCoordinates[currentRouteIndex];
      });
      _updateRouteSegments();
      _drawRouteAndMarkers();
      _followDriver();
    } else {
      _driverMovementTimer?.cancel();
      if (mounted)
        setState(() {
          isDriverMoving = false;
          hasArrived = true;
        });
      _updateRadiationPosition();
      _drawRouteAndMarkers();
    }
  }

  void _followDriver() {
    if (!mounted || !_mapReady) return;
    _mapboxMap.setCamera(
      mapbox.CameraOptions(
        center: mapbox.Point(coordinates: currentDriverPosition),
        zoom: 15.5,
        pitch: 0.0,
        bearing: 0.0,
      ),
    );
  }

  String _calculateArrivalTime(int durationMinutes) {
    final now = DateTime.now().toUtc().add(const Duration(hours: 5)); // +05 vaqt zonasi
    final arrival = now.add(Duration(minutes: durationMinutes));
    final endTime = arrival.add(const Duration(minutes: 20));
    return '${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}-${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
  }

  int _hexToInt(String hex) {
    String cleanedHex = hex.replaceAll('#', '');
    if (cleanedHex.length == 6) cleanedHex = 'FF$cleanedHex';
    return int.parse(cleanedHex, radix: 16);
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Buyurtmani bekor qilish'),
          content: const Text('Haqiqatan ham buyurtmani bekor qilmoqchimisiz?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Yo\'q'),
            ),
            TextButton(
              onPressed: () {
                context.read<OrdersBloc>().add(CancelOrderEvent());
                context.read<OrdersBloc>().add(DisConnectFromWebSocketEvent());

                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MainScreen()));
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Ha, bekor qil'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _driverMovementTimer?.cancel();
    _debounceTimer?.cancel();
    _searchTimer?.cancel();
    _polylineAnnotationManager?.deleteAll();
    _pointAnnotationManager?.deleteAll();
    context.read<OrdersBloc>().add(DisConnectFromWebSocketEvent());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          BlocListener<OrdersBloc, OrdersState>(
            listener: (context, state) {
              if (state.orderAccepted != null) {
                _processOrderAcceptedData(state.orderAccepted!);
              }
            },
          ),
          BlocListener<OrdersBloc, OrdersState>(
            listenWhen: (previous, current) => previous.currentOrderStatus != current.currentOrderStatus,
            listener: (context, state) {},
          ),
        ],
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              padding: EdgeInsets.only(
                bottom: isLoading
                    ? 0
                    : MediaQuery.of(context).padding.bottom + (MediaQuery.of(context).size.height * 0.3),
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
                  zoom: 15.5,
                  pitch: 0.0,
                  bearing: 0.0,
                ),
                onCameraChangeListener: (cameraChanged) {
                  setState(() => isScrolling = true);
                  _debounceTimer?.cancel();
                  _debounceTimer = Timer(const Duration(milliseconds: 400), () {
                    if (mounted) {
                      setState(() => isScrolling = false);
                      if (hasArrived && !isScrolling) _updateRadiationPosition();
                    }
                  });
                },
              ),
            ),
            BeautifulRadiationWidget(
              isVisible: isLoading || hasArrived,
              position: isLoading
                  ? Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2)
                  : radiationPosition,
            ),
            if (isLoading)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 333,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColor.blueMain),
                          strokeWidth: 4.0,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Usta buyurtma qabul qilishi kutilmoqda...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Odatda haydovchi 1 daqiqa ichida topiladi ($_searchSeconds soniya)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() => isLoading = false);
                            _searchTimer?.cancel();
                            context.read<OrdersBloc>().add(DisConnectFromWebSocketEvent());
                            // Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'Bekor qilish',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (!isLoading)
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
                      boxShadow: [BoxShadow(blurRadius: 16, color: Colors.black.withOpacity(0.08))],
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
                              if (!isLoading && !hasArrived)
                                Column(
                                  children: [
                                    Text(
                                      'Usta buyurtmani qabul qildi, va siz tomon harakatlanmoqda!',
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
                                      'Kelish vaqti',
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
                                      estimatedArrivalTime,
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
                                  ],
                                ),
                              if (hasArrived)
                                Column(
                                  children: [
                                    Text(
                                      'Usta keldi va yaqin daqiqalarda ishni boshlaydi.',
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
                                      'Tahminiy ish vaqti',
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
                                      '40 daqiqa',
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
                                        _stepIcon(AppIcons.maploc, true),
                                        _stepLine(),
                                        _stepIcon(AppIcons.pair, false),
                                        _stepLine(),
                                        _stepIcon(AppIcons.finishflag, false),
                                      ],
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                        if (!isLoading)
                          Column(
                            children: [
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                width: double.infinity,
                                decoration: const ShapeDecoration(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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
                                        CircleAvatar(
                                          radius: 26,
                                          backgroundImage: NetworkImage(
                                            mechanicPhoto ??
                                                'https://azamov.me/assets/images//2024-09-26%2015.09.48.jpg',
                                          ),
                                        ),
                                        const SizedBox(width: 11),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                mechanicName,
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 14.5,
                                                  fontFamily: 'Inter',
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: -0.30,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Spacer(),
                                        GestureDetector(
                                          onTap: () {
                                            // Call mechanic functionality
                                            print('Calling: $mechanicPhone');
                                          },
                                          child: Column(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: const ShapeDecoration(
                                                  color: Color(0xFFEFF2F5),
                                                  shape: CircleBorder(),
                                                ),
                                                child: SvgPicture.asset(AppIcons.call, height: 30, width: 30),
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
                                        ),
                                        const Spacer(),
                                        GestureDetector(
                                          onTap: () {
                                            // Show order details
                                            context.push(Pages.orderInfo);

                                            print('Show order details');
                                          },
                                          child: Column(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: const ShapeDecoration(
                                                  color: Color(0xFFEFF2F5),
                                                  shape: CircleBorder(),
                                                ),
                                                child: SvgPicture.asset(AppIcons.about, height: 30, width: 30),
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
                                        ),
                                        const Spacer(),
                                        GestureDetector(
                                          onTap: () {
                                            // Cancel order functionality
                                            _showCancelDialog();
                                          },
                                          child: Column(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: const ShapeDecoration(
                                                  color: Color(0xFFEFF2F5),
                                                  shape: CircleBorder(),
                                                ),
                                                child: SvgPicture.asset(AppIcons.close, height: 30, width: 30),
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
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 50,
              left: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    context.read<OrdersBloc>().add(DisConnectFromWebSocketEvent());
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepIcon(String icon, bool active) {
    return CircleAvatar(
      backgroundColor: active ? AppColor.blueMain : AppColor.greyBg,
      radius: 24,
      child: SvgPicture.asset(icon, color: active ? AppColor.white : AppColor.black),
    );
  }

  Widget _stepLine() {
    return Container(width: 40, height: 2, color: const Color(0xffCDD8EA));
  }
}

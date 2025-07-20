import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:http/http.dart' as http;
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_images.dart';
import 'dart:convert';
import '../../../../core/constants/color/app_icons.dart';

class OrderProccessScreen extends StatefulWidget {
  const OrderProccessScreen({super.key});

  @override
  State<OrderProccessScreen> createState() => _OrderProccessScreenState();
}

class _OrderProccessScreenState extends State<OrderProccessScreen> {
  late mapbox.MapboxMap _mapboxMap;
  mapbox.Position currentPosition = mapbox.Position(0.0, 0.0);
  bool isScrolling = false;
  Timer? _debounceTimer;
  mapbox.PolylineAnnotationManager? _polylineAnnotationManager;
  mapbox.PointAnnotationManager? _pointAnnotationManager;

  // Coordinates for PDP Academy and Chilanzar
  final mapbox.Position startPosition = mapbox.Position(
    69.2047,
    41.2806,
  ); // PDP Academy
  final mapbox.Position endPosition = mapbox.Position(
    69.2056,
    41.2789,
  ); // Chilanzar (Metro Station)

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    geolocator.Position? position = await getCurrentLocation();
    if (position != null) {
      setState(() {
        currentPosition = mapbox.Position(
          position.longitude,
          position.latitude,
        );
        isScrolling = false;
      });
      // Center map on midpoint between PDP Academy and Chilanzar
      final midpoint = mapbox.Position(
        (startPosition.lng + endPosition.lng) / 2,
        (startPosition.lat + endPosition.lat) / 2,
      );
      _mapboxMap.setCamera(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: midpoint),
          zoom: 14.0, // Closer zoom for clarity
          pitch: 0.0,
          bearing: 0.0,
        ),
      );
      // Fetch and draw the route
      await _fetchAndDrawRoute();
    }
  }

  void _onMapCreated(mapbox.MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    // Center map on midpoint between PDP Academy and Chilanzar
    final midpoint = mapbox.Position(
      (startPosition.lng + endPosition.lng) / 2,
      (startPosition.lat + endPosition.lat) / 2,
    );
    _mapboxMap.setCamera(
      mapbox.CameraOptions(
        center: mapbox.Point(coordinates: midpoint),
        zoom: 14.0,
        pitch: 0.0,
        bearing: 0.0,
      ),
    );
    // Disable terrain to avoid DEM warning
    // Initialize PolylineAnnotationManager and PointAnnotationManager
    _mapboxMap.annotations.createPolylineAnnotationManager().then((
      polylineManager,
    ) {
      _polylineAnnotationManager = polylineManager;
    });
    _mapboxMap.annotations.createPointAnnotationManager().then((pointManager) {
      _pointAnnotationManager = pointManager;
      // Draw route after managers are initialized
      _fetchAndDrawRoute();
    });
  }

  // Helper function to convert hex color to integer
  int _hexToInt(String hex) {
    String cleanedHex = hex.replaceAll('#', '');
    if (cleanedHex.length == 6) {
      cleanedHex = 'FF$cleanedHex'; // Add alpha channel if not provided
    }
    return int.parse(cleanedHex, radix: 16);
  }

  // Fetch route from Mapbox Directions API
  Future<void> _fetchAndDrawRoute() async {
    if (_polylineAnnotationManager == null || _pointAnnotationManager == null)
      return;

    const String accessToken =
        'pk.eyJ1IjoiYXphbW92IiwiYSI6ImNtY2hzbjFibjB3cHMycm45N2lkaTZnMWQifQ.6stCvz6FLKcLLhiUEW2NFQ';
    final String url =
        'https://api.mapbox.com/directions/v5/mapbox/driving/${startPosition.lng},${startPosition.lat};${endPosition.lng},${endPosition.lat}?geometries=geojson&access_token=$accessToken';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> coordinates =
            data['routes'][0]['geometry']['coordinates'];

        // Convert coordinates to Mapbox LineString
        final List<mapbox.Position> routePositions = coordinates
            .map((coord) => mapbox.Position(coord[0], coord[1]))
            .toList();
        final lineString = mapbox.LineString(coordinates: routePositions);

        // Clear existing polylines
        await _polylineAnnotationManager?.deleteAll();

        // Draw the route as a polyline
        await _polylineAnnotationManager?.create(
          mapbox.PolylineAnnotationOptions(
            geometry: lineString,
            lineColor: _hexToInt('#007AFF'), // Blue route line
            lineWidth: 6.0, // Thicker line for clarity
            lineOpacity: 0.9,
          ),
        );

        // Clear existing point annotations
        await _pointAnnotationManager?.deleteAll();

        // Add enhanced markers for PDP Academy and Chilanzar
        await _pointAnnotationManager?.createMulti([
          mapbox.PointAnnotationOptions(
            geometry: mapbox.Point(coordinates: startPosition),
            textField: 'PDP Academy',
            textColor: _hexToInt('#000000'),
            textHaloColor: _hexToInt('#FFFFFF'),
            iconImage: AppImages.massage,
            textHaloWidth: 3.0,
            textSize: 14.0,
            // Larger text
            textOffset: [0.0, -2.0], // Position text above marker
          ),
          mapbox.PointAnnotationOptions(
            geometry: mapbox.Point(coordinates: endPosition),
            textField: 'Chilanzar',
            textColor: _hexToInt('#000000'),
            textHaloColor: _hexToInt('#FFFFFF'),
            textHaloWidth: 3.0,
            textSize: 14.0,
            textOffset: [0.0, -2.0],
          ),
        ]);
      } else {
        print('Failed to fetch route: ${response.statusCode}');
        print('Response body: ${response.body}');
        // Draw fallback route if API fails
        _drawFallbackRoute();
      }
    } catch (e) {
      print('Error fetching route: $e');
      // Draw fallback route if API fails
      _drawFallbackRoute();
    }
  }

  // Fallback route in case API fails
  Future<void> _drawFallbackRoute() async {
    if (_polylineAnnotationManager == null || _pointAnnotationManager == null)
      return;

    // Hardcoded route for testing
    final List<mapbox.Position> routePositions = [
      startPosition, // PDP Academy
      endPosition, // Chilanzar
    ];
    final lineString = mapbox.LineString(coordinates: routePositions);

    // Clear existing polylines
    await _polylineAnnotationManager?.deleteAll();

    // Draw the route as a polyline
    await _polylineAnnotationManager?.create(
      mapbox.PolylineAnnotationOptions(
        geometry: lineString,
        lineColor: _hexToInt('#007AFF'),
        lineWidth: 6.0,
        lineOpacity: 0.9,
      ),
    );

    // Clear existing point annotations
    await _pointAnnotationManager?.deleteAll();

    // Add enhanced markers for PDP Academy and Chilanzar
    await _pointAnnotationManager?.createMulti([
      mapbox.PointAnnotationOptions(
        geometry: mapbox.Point(coordinates: startPosition),
        textField: 'PDP Academy',
        textColor: _hexToInt('#000000'),
        textHaloColor: _hexToInt('#FFFFFF'),
        textHaloWidth: 3.0,
        textSize: 14.0,
        textOffset: [0.0, -2.0],
      ),
      mapbox.PointAnnotationOptions(
        geometry: mapbox.Point(coordinates: endPosition),
        textField: 'Chilanzar',
        textColor: _hexToInt('#000000'),
        textHaloColor: _hexToInt('#FFFFFF'),
        textHaloWidth: 3.0,
        textSize: 14.0,
        textOffset: [0.0, -2.0],
      ),
    ]);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _polylineAnnotationManager?.deleteAll();
    _pointAnnotationManager?.deleteAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. MAP (to'liq ekran)
          Expanded(
            child: mapbox.MapWidget(
              key: const ValueKey('mapWidget'),
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
                zoom: 15.0,
                bearing: 0.0,
              ),
              onCameraChangeListener: (cameraChanged) {
                setState(() {
                  isScrolling = true;
                });
                if (_debounceTimer?.isActive ?? false) {
                  _debounceTimer!.cancel();
                }
                _debounceTimer = Timer(const Duration(milliseconds: 400), () {
                  _mapboxMap.getCameraState().then((cameraPosition) {
                    setState(() {
                      isScrolling = false;
                    });
                  });
                });
              },
            ),
          ),
          // 2. Back Button with Clipped Corners (pastda joylashtirilgan)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0, // Pastga joylashtirish
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)), // Yuqori burchaklarga radius
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColor.greyBg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)), // Yuqori burchaklarga radius
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
                    // Sheet drag indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      width: double.infinity,
                      decoration: ShapeDecoration(
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
                          // Title
                          Text(
                            'Usta buyurtmani qabul qildi, va siz tomon harakatlanmoqda!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 19,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              height: 1.40,
                              letterSpacing: -0.30,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Kelish vaqti',
                            style: TextStyle(
                              color: const Color(0xFF6B7073),
                              fontSize: 13.5,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              height: 1.40,
                              letterSpacing: -0.30,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '17:00-17:10', // Joriy vaqt 05:54 PM +05 (20-iyul, 2025), bu vaqt o‘tgan
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              height: 1.40,
                              letterSpacing: -0.30,
                            ),
                          ),
                          SizedBox(height: 16),
                          // Stepper icons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _stepIcon(AppIcons.rocket, true),
                              _stepLine(),
                              _stepIcon(AppIcons.maploc, false),
                              _stepLine(),
                              _stepIcon(AppIcons.pair, false),
                              _stepLine(),
                              _stepIcon(AppIcons.finishflag, false),
                            ],
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      width: double.infinity,
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 13),
                          Text(
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
                          SizedBox(height: 13),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundImage: NetworkImage(
                                  'https://azamov.me/assets/images//2024-09-26%2015.09.48.jpg',
                                ),
                              ),
                              SizedBox(width: 11),
                              Expanded(
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
                                        color: const Color(0xFF6B7073),
                                        fontSize: 12.5,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: -0.30,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Spacer(),
                              TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                  backgroundColor: AppColor.greyBg,
                                ),
                                onPressed: () {},
                                child: Text(
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
                          SizedBox(height: 13),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 13, horizontal: 44),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Spacer(),
                              Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: ShapeDecoration(
                                      color: const Color(0xFFEFF2F5),
                                      shape: CircleBorder(),
                                    ),
                                    child: SvgPicture.asset(
                                      height: 30,
                                      width: 30,
                                      AppIcons.call,
                                    ),
                                  ),
                                  SizedBox(height: 7),
                                  Text(
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
                              Spacer(),
                              Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: ShapeDecoration(
                                      color: const Color(0xFFEFF2F5),
                                      shape: CircleBorder(),
                                    ),
                                    child: SvgPicture.asset(
                                      height: 30,
                                      width: 30,
                                      AppIcons.about,
                                    ),
                                  ),
                                  SizedBox(height: 7),
                                  Text(
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
                              Spacer(),
                              Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: ShapeDecoration(
                                      color: const Color(0xFFEFF2F5),
                                      shape: CircleBorder(),
                                    ),
                                    child: SvgPicture.asset(
                                      height: 30,
                                      width: 30,
                                      AppIcons.close,
                                    ),
                                  ),
                                  SizedBox(height: 7),
                                  Text(
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
                              Spacer(),
                            ],
                          ),
                          SizedBox(height: 11),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 3. Back Button
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.of(context).pop();
                },
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
    return Container(width: 40, height: 2, color: Color(0xffCDD8EA));
  }

  Future<geolocator.Position?> getCurrentLocation() async {
    try {
      geolocator.LocationPermission permission =
          await geolocator.Geolocator.checkPermission();
      if (permission == geolocator.LocationPermission.denied) {
        permission = await geolocator.Geolocator.requestPermission();
        if (permission == geolocator.LocationPermission.denied) {
          print('Location ruxsati rad etildi');
          return null;
        }
      }
      if (permission == geolocator.LocationPermission.deniedForever) {
        print('Location ruxsati doimiy ravishda rad etildi');
        return null;
      }

      geolocator.Position position =
          await geolocator.Geolocator.getCurrentPosition(
            desiredAccuracy: geolocator.LocationAccuracy.high,
          );
      print('Hozirgi joylashuv: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('Hozirgi joylashuvni olishda xatolik: $e');
      return null;
    }
  }
}

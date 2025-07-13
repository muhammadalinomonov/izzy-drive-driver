import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/features/map/data/model/nearby_masters_response.dart';
import 'package:flutter/services.dart';
import 'package:taxi_app/src/routes/pages.dart';
import '../../data/repo/map_repo_imp.dart';
import '../../data/source/map_data_source.dart';
import '../bloc/map_bloc.dart';
import '../widgets/search_location_bottomsheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late mapbox.MapboxMap _mapboxMap;
  mapbox.Position currentPosition = mapbox.Position(0.0, 0.0);
  mapbox.Point? selectedLocation;
  bool isScrolling = false;
  Timer? _debounceTimer;
  mapbox.Position? _lastFetchedPosition; // Cache last fetched coordinates
  static const double _distanceThreshold = 100.0; // Meters
  mapbox.PointAnnotationManager? _annotationManager; // Add this line

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
      if (_shouldFetchMechanics(position.latitude, position.longitude)) {
        _lastFetchedPosition = mapbox.Position(
          position.longitude,
          position.latitude,
        );
        context.read<MapBloc>().add(
          FetchNearbyMechanicsEvent(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        );
      }
      _mapboxMap.setCamera(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: currentPosition),
          zoom: 16.6,
          pitch: 0.0,
          bearing: 0.0,
        ),
      );
    }
  }

  bool _shouldFetchMechanics(double newLat, double newLng) {
    if (_lastFetchedPosition == null) return true;
    final distance = geolocator.Geolocator.distanceBetween(
      _lastFetchedPosition!.lat.toDouble(),
      _lastFetchedPosition!.lng.toDouble(),
      newLat,
      newLng,
    );
    return distance > _distanceThreshold;
  }

  void _onMapCreated(mapbox.MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;

    mapboxMap.setCamera(
      mapbox.CameraOptions(
        center: mapbox.Point(coordinates: currentPosition),
        zoom: 30.0,
        pitch: 0.0,
        bearing: 0.0,
      ),
    );
  }

  Future<Uint8List> _loadPngMarker() async {
    try {
      final String assetPath = AppIcons.master;
      if (assetPath.isEmpty) {
        throw Exception('Asset manzili bo‘sh!');
      }
      final ByteData data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (e) {
      print('PNG yuklashda xatolik: $e');
      return Uint8List.fromList([]);
    }
  }

  Future<Uint8List> _drawMarkerWithPill(
    Uint8List iconBytes,
    String text,
  ) async {
    // 1. Master ikonkasini Image ob’ektiga aylantiramiz
    final codec = await ui.instantiateImageCodec(iconBytes);
    final frame = await codec.getNextFrame();
    final iconImage = frame.image;

    // 2. Matnni formatlaymiz
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 53, color: Colors.black),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // 3. Pill uchun padding va o‘lcham
    const double padH = 8, padV = 4;
    final pillW = tp.width + padH * 2;
    final pillH = tp.height + padV * 2;

    // 4. Canvas o‘lchamini aniqlaymiz:
    //    butun marker – ikonka balandligi + pastda pill bo‘lishi uchun joy
    final totalW = max(iconImage.width.toDouble(), pillW / 2);
    final totalH = iconImage.height.toDouble() + pillH / 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 5. Ikonkani chizamiz, tepada markazlashgan holda
    final iconOffset = Offset((totalW - iconImage.width) / 2, 0);
    canvas.drawImage(iconImage, iconOffset, Paint());

    // 6. Pastki yostiqcha (“pill”) uchun dumaloq to‘rtburchak
    final pillX = (totalW - pillW) / 2;
    final pillY = iconImage.height.toDouble() - pillH / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pillX, pillY, pillW, pillH),
      Radius.circular(pillH / 2),
    );
    canvas.drawRRect(rrect, Paint()..color = Colors.white);

    // 7. Matnni pill’ning ichiga chizamiz
    final textX = pillX + padH;
    final textY = pillY + padV;
    tp.paint(canvas, Offset(textX, textY));

    // 8. Suratni Uint8List ga aylantiramiz
    final picture = recorder.endRecording();
    final img = await picture.toImage(totalW.ceil(), totalH.ceil());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  // 1. _addMarkers metodini yangilang:
  void _addMarkers(List<Mechanic> mechanics) async {
    final annotationManager = await _mapboxMap.annotations
        .createPointAnnotationManager();
    await annotationManager.deleteAll();
    for (var mech in mechanics) {
      final iconBytes = await _loadPngMarker();
      final combined = await _drawMarkerWithPill(
        iconBytes,
        '${mech.distance.toStringAsFixed(1)} km',
      );

      annotationManager.create(
        mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position(
              mech.longitude.toDouble(),
              mech.latitude.toDouble(),
            ),
          ),
          image: combined,
          iconSize: 0.6,
        ),
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapbox Xarita')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                BlocConsumer<MapBloc, MapState>(
                  listener: (context, state) async {
                    if (state is MapSuccess) {
                      // Fetch nearby mechanics and add markers
                      _annotationManager = await _mapboxMap.annotations
                          .createPointAnnotationManager();
                      await _annotationManager
                          ?.deleteAll(); // Clear existing markers

                      _addMarkers(state.nearbyMechanics.data.mechanics);
                    } else if (state is MapFailure) {}
                  },
                  builder: (context, state) {
                    return Stack(
                      children: [
                        mapbox.MapWidget(
                          key: const ValueKey('mapWidget'),
                          styleUri: mapbox.MapboxStyles.STANDARD,
                          onMapCreated: _onMapCreated,
                          cameraOptions: mapbox.CameraOptions(
                            center: mapbox.Point(coordinates: currentPosition),
                            pitch: 0.0,
                            zoom: 1.0,
                            bearing: 0.0,
                          ),
                          onCameraChangeListener: (cameraChanged) {
                            setState(() {
                              isScrolling = true;
                            });
                            if (_debounceTimer?.isActive ?? false) {
                              _debounceTimer!.cancel();
                            }
                            _debounceTimer = Timer(
                              const Duration(milliseconds: 400),
                              () {
                                _mapboxMap.getCameraState().then((
                                  cameraPosition,
                                ) {
                                  setState(() {
                                    selectedLocation = cameraPosition.center;
                                    isScrolling = false;
                                    print(
                                      'Tanlangan joy: ${selectedLocation?.coordinates.lat}, ${selectedLocation?.coordinates.lng}',
                                    );
                                    // Only fetch if not scrolling, not loading, and significant movement
                                    if (!isScrolling &&
                                        state is! MapLoading &&
                                        selectedLocation != null &&
                                        _shouldFetchMechanics(
                                          selectedLocation!.coordinates.lat
                                              .toDouble(),
                                          selectedLocation!.coordinates.lng
                                              .toDouble(),
                                        )) {
                                      _lastFetchedPosition = mapbox.Position(
                                        selectedLocation!.coordinates.lng
                                            .toDouble(),
                                        selectedLocation!.coordinates.lat
                                            .toDouble(),
                                      );
                                      context.read<MapBloc>().add(
                                        FetchNearbyMechanicsEvent(
                                          latitude: selectedLocation!
                                              .coordinates
                                              .lat
                                              .toDouble(),
                                          longitude: selectedLocation!
                                              .coordinates
                                              .lng
                                              .toDouble(),
                                        ),
                                      );
                                    }
                                  });
                                });
                              },
                            );
                          },
                        ),
                        if (state is MapLoading)
                          const Center(child: CircularProgressIndicator()),
                      ],
                    );
                  },
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: isScrolling ? 50.0 : 0.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Card(
                          margin: EdgeInsets.zero,
                          color: AppColor.blueMain,
                          elevation: 8,
                          shape: const CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.all(11.0),
                            child: SvgPicture.asset(
                              AppIcons.truck,
                              color: Colors.white,
                              width: 18,
                              height: 18,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Container(width: 2, height: 25, color: Colors.black),
                        Container(
                          width: isScrolling ? 12 : 7,
                          height: isScrolling ? 7 : 4,
                          decoration: ShapeDecoration(
                            color: Colors.black.withValues(
                              alpha: isScrolling ? 0.32 : 0.25,
                            ),
                            shape: OvalBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16.0,
                  left: 16.0,
                  child: SizedBox(
                    height: 50,
                    width: 50,
                    child: FloatingActionButton(
                      elevation: 1,
                      highlightElevation: 1,
                      mini: false,
                      backgroundColor: Colors.white,
                      shape: const CircleBorder(),
                      onPressed: () {
                        Navigator.of(context).pop(); // Go back
                      },
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 25,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16.0,
                  right: 16.0,
                  child: SizedBox(
                    height: 50,
                    width: 50,
                    child: FloatingActionButton(
                      elevation: 1,
                      highlightElevation: 1,
                      mini: false,
                      backgroundColor: Colors.white,
                      shape: const CircleBorder(),
                      onPressed: _fetchLocation,
                      child: Icon(
                        Icons.location_on_outlined,
                        color: AppColor.blueMain,
                        size: 25,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocBuilder<MapBloc, MapState>(
                  builder: (context, state) {
                    String address = 'Joy tanlanmadi';
                    if (state is MapSuccess) {
                      address = state
                          .nearbyMechanics
                          .data
                          .driverCurrentAddress
                          .address;
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 10,
                      ),
                      width: double.infinity,
                      decoration: ShapeDecoration(
                        color: const Color(0xFFEFF2F5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(AppIcons.truck),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                showAddressBottomSheet(
                                  context,
                                  currentPosition,
                                  getMyLocation: () {
                                    // Fetch current location when tapped
                                    _fetchLocation();
                                  },
                                  onSelected: (locationData) {
                                    // Update selectedLocation with the new coordinates
                                    setState(() {
                                      selectedLocation = mapbox.Point(
                                        coordinates: mapbox.Position(
                                          locationData.lon,
                                          locationData.lat,
                                        ),
                                      );
                                      currentPosition = mapbox.Position(
                                        locationData.lon,
                                        locationData.lat,
                                      );
                                    });

                                    // Update the map camera to center on the selected location
                                    _mapboxMap.setCamera(
                                      mapbox.CameraOptions(
                                        center: mapbox.Point(
                                          coordinates: mapbox.Position(
                                            locationData.lon,
                                            locationData.lat,
                                          ),
                                        ),
                                        zoom: 16.0,
                                        pitch: 0.0,
                                        bearing: 0.0,
                                      ),
                                    );

                                    // Update last fetched position to avoid redundant fetches
                                    _lastFetchedPosition = mapbox.Position(
                                      locationData.lon,
                                      locationData.lat,
                                    );

                                    // Fetch nearby mechanics for the selected location
                                    context.read<MapBloc>().add(
                                      FetchNearbyMechanicsEvent(
                                        latitude: locationData.lat,
                                        longitude: locationData.lon,
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Text(
                                address,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.30,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16.0),
                SizedBox(
                  width: double.infinity,
                  child: MaterialButton(
                    onPressed: () {
                      if (selectedLocation != null) {
                        print(
                          'Davom etish: ${selectedLocation!.coordinates.lat}, ${selectedLocation!.coordinates.lng}',
                        );
                        context.go(Pages.main);
                      } else {
                        print('Joy tanlanmadi');
                      }
                    },
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    highlightElevation: 0,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: AppColor.blueMain,
                    textColor: Colors.white,
                    child: const Text('Davom etish'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

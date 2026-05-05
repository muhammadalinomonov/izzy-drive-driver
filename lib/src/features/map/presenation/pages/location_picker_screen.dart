import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/features/map/data/model/nearby_masters_response.dart';
import 'package:taxi_app/src/features/map/data/model/search_locations_response.dart';
import 'package:taxi_app/src/features/map/presenation/bloc/map_bloc.dart';
import 'package:taxi_app/src/routes/pages.dart';

/// Single screen for choosing the destination address.
///
/// Two visual modes driven by [MapBloc.state.pickerMode]:
/// - [PickerMode.map]: full-screen Mapbox + center pin + nearby mechanic
///   markers + small bottom sheet with address chip and "Davom ettirish".
/// - [PickerMode.list]: bottom sheet expanded over dimmed map; user types
///   to search via `/drivers/typing/`, picks an address, returns to map mode.
///
/// On "Davom ettirish" the selected address+coords are forwarded to the
/// order-create wizard via `context.push(Pages.orderCreate, extra: {...})`.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  mapbox.MapboxMap? _map;
  mapbox.PointAnnotationManager? _annotationManager;

  mapbox.Position _currentPosition = mapbox.Position(69.2401, 41.2995); // Tashkent fallback
  mapbox.Position? _lastFetchedPosition;
  static const double _distanceThresholdMeters = 100.0;

  Timer? _debounceTimer;
  Timer? _searchDebounce;
  bool _isPanning = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initFromCurrentLocation();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initFromCurrentLocation({bool animate = false}) async {
    final pos = await _readGpsPosition();
    if (pos == null || !mounted) return;
    setState(() {
      _currentPosition = mapbox.Position(pos.longitude, pos.latitude);
    });
    final map = _map;
    if (map != null) {
      final cameraOptions = mapbox.CameraOptions(
        center: mapbox.Point(coordinates: _currentPosition),
        zoom: 16.0,
      );
      if (animate) {
        await map.flyTo(
          cameraOptions,
          mapbox.MapAnimationOptions(duration: 600),
        );
      } else {
        await map.setCamera(cameraOptions);
      }
    }
    _maybeFetchMechanics(pos.latitude, pos.longitude, force: true);
  }

  Future<geolocator.Position?> _readGpsPosition() async {
    try {
      var permission = await geolocator.Geolocator.checkPermission();
      if (permission == geolocator.LocationPermission.denied) {
        permission = await geolocator.Geolocator.requestPermission();
        if (permission == geolocator.LocationPermission.denied) return null;
      }
      if (permission == geolocator.LocationPermission.deniedForever) return null;
      return await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  bool _shouldFetch(double newLat, double newLng) {
    if (_lastFetchedPosition == null) return true;
    final distance = geolocator.Geolocator.distanceBetween(
      _lastFetchedPosition!.lat.toDouble(),
      _lastFetchedPosition!.lng.toDouble(),
      newLat,
      newLng,
    );
    return distance > _distanceThresholdMeters;
  }

  void _maybeFetchMechanics(double lat, double lng, {bool force = false}) {
    if (!force && !_shouldFetch(lat, lng)) return;
    _lastFetchedPosition = mapbox.Position(lng, lat);
    context.read<MapBloc>().add(
      FetchNearbyMechanicsEvent(latitude: lat, longitude: lng),
    );
  }

  void _onMapCreated(mapbox.MapboxMap map) {
    _map = map;
    map.setCamera(mapbox.CameraOptions(
      center: mapbox.Point(coordinates: _currentPosition),
      zoom: 16.0,
    ));
  }

  void _onCameraChange(mapbox.CameraChangedEventData _) {
    setState(() => _isPanning = true);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      final map = _map;
      if (map == null) return;
      final cam = await map.getCameraState();
      if (!mounted) return;
      setState(() => _isPanning = false);
      final lat = cam.center.coordinates.lat.toDouble();
      final lng = cam.center.coordinates.lng.toDouble();
      _maybeFetchMechanics(lat, lng);
    });
  }

  Future<Uint8List> _composeMarkerPng(double distanceKm) async {
    final iconBytes = (await rootBundle.load(AppIcons.master)).buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(iconBytes);
    final frame = await codec.getNextFrame();
    final iconImage = frame.image;

    final tp = TextPainter(
      text: TextSpan(
        text: '${distanceKm.toStringAsFixed(1)} km',
        style: const TextStyle(fontSize: 53, color: Colors.black),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const padH = 8.0, padV = 4.0;
    final pillW = tp.width + padH * 2;
    final pillH = tp.height + padV * 2;
    final totalW = max(iconImage.width.toDouble(), pillW / 2);
    final totalH = iconImage.height.toDouble() + pillH / 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(
      iconImage,
      Offset((totalW - iconImage.width) / 2, 0),
      Paint(),
    );
    final pillX = (totalW - pillW) / 2;
    final pillY = iconImage.height.toDouble() - pillH / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pillX, pillY, pillW, pillH),
        Radius.circular(pillH / 2),
      ),
      Paint()..color = Colors.white,
    );
    tp.paint(canvas, Offset(pillX + padH, pillY + padV));

    final picture = recorder.endRecording();
    final img = await picture.toImage(totalW.ceil(), totalH.ceil());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  Future<void> _drawMechanicMarkers(List<Mechanic> mechanics) async {
    final map = _map;
    if (map == null) return;
    _annotationManager ??= await map.annotations.createPointAnnotationManager();
    await _annotationManager!.deleteAll();
    for (final m in mechanics) {
      final png = await _composeMarkerPng(m.distance);
      await _annotationManager!.create(
        mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position(m.longitude.toDouble(), m.latitude.toDouble()),
          ),
          image: png,
          iconSize: 0.6,
        ),
      );
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<MapBloc>().add(FetchNearbyLocationsEvent(
        latitude: _currentPosition.lat.toDouble(),
        longitude: _currentPosition.lng.toDouble(),
        query: value,
      ));
    });
  }

  void _selectSuggestion(LocationData loc) {
    context.read<MapBloc>().add(LocationSelectedEvent(
      address: loc.formatted,
      latitude: loc.lat,
      longitude: loc.lon,
    ));
    setState(() {
      _currentPosition = mapbox.Position(loc.lon, loc.lat);
    });
    _map?.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(coordinates: _currentPosition),
        zoom: 16.0,
      ),
      mapbox.MapAnimationOptions(duration: 600),
    );
    _maybeFetchMechanics(loc.lat, loc.lon, force: true);
    _searchController.clear();
  }

  void _useMyLocation() {
    _initFromCurrentLocation(animate: true);
    context.read<MapBloc>().add(PickerModeChangedEvent(PickerMode.map));
  }

  void _continueToOrderCreate() {
    final state = context.read<MapBloc>().state;
    final lat = state.selectedLatitude ?? _currentPosition.lat.toDouble();
    final lng = state.selectedLongitude ?? _currentPosition.lng.toDouble();
    final address = state.selectedAddress.isEmpty
        ? 'Tanlangan joy'
        : state.selectedAddress;
    context.push(Pages.orderCreate, extra: {
      'address': address,
      'latitude': lat,
      'longitude': lng,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<MapBloc, MapState>(
        listenWhen: (p, c) =>
            p.mechanicsStatus != c.mechanicsStatus ||
            p.nearbyMechanics != c.nearbyMechanics,
        listener: (context, state) {
          if (state.mechanicsStatus == MapStatus.success &&
              state.nearbyMechanics != null) {
            _drawMechanicMarkers(state.nearbyMechanics!.data.mechanics);
          }
        },
        builder: (context, state) {
          return Stack(
            fit: StackFit.expand,
            children: [
              mapbox.MapWidget(
                key: const ValueKey('locationPickerMap'),
                styleUri: mapbox.MapboxStyles.STANDARD,
                onMapCreated: _onMapCreated,
                onCameraChangeListener: _onCameraChange,
                cameraOptions: mapbox.CameraOptions(
                  center: mapbox.Point(coordinates: _currentPosition),
                  zoom: 16.0,
                ),
              ),
              _CenterPinOverlay(isPanning: _isPanning),
              if (state.mechanicsStatus == MapStatus.loading)
                const Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              _BackFab(onPressed: () => context.pop()),
              _MyLocationFab(onPressed: _useMyLocation),
              if (state.pickerMode == PickerMode.map)
                _MapModeSheet(
                  address: state.selectedAddress,
                  onTapAddressChip: () => context
                      .read<MapBloc>()
                      .add(PickerModeChangedEvent(PickerMode.list)),
                  onContinue: _continueToOrderCreate,
                )
              else
                _ListModeSheet(
                  searchController: _searchController,
                  state: state,
                  onSearchChanged: _onSearchChanged,
                  onUseMyLocation: _useMyLocation,
                  onSuggestionTap: _selectSuggestion,
                  onClose: () => context
                      .read<MapBloc>()
                      .add(PickerModeChangedEvent(PickerMode.map)),
                  onConfirm: _continueToOrderCreate,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CenterPinOverlay extends StatelessWidget {
  const _CenterPinOverlay({required this.isPanning});
  final bool isPanning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isPanning ? 50.0 : 0.0),
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
              width: isPanning ? 12 : 7,
              height: isPanning ? 7 : 4,
              decoration: ShapeDecoration(
                color: Colors.black.withValues(alpha: isPanning ? 0.32 : 0.25),
                shape: const OvalBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackFab extends StatelessWidget {
  const _BackFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 12,
      left: 16,
      child: SizedBox(
        height: 50,
        width: 50,
        child: FloatingActionButton(
          heroTag: 'picker_back',
          elevation: 1,
          backgroundColor: Colors.white,
          shape: const CircleBorder(),
          onPressed: onPressed,
          child: const Icon(Icons.arrow_back, color: Colors.black, size: 25),
        ),
      ),
    );
  }
}

class _MyLocationFab extends StatelessWidget {
  const _MyLocationFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 220,
      right: 16,
      child: SizedBox(
        height: 50,
        width: 50,
        child: FloatingActionButton(
          heroTag: 'picker_mylocation',
          elevation: 1,
          backgroundColor: Colors.white,
          shape: const CircleBorder(),
          onPressed: onPressed,
          child: Icon(Icons.location_on_outlined,
              color: AppColor.blueMain, size: 25),
        ),
      ),
    );
  }
}

class _MapModeSheet extends StatelessWidget {
  const _MapModeSheet({
    required this.address,
    required this.onTapAddressChip,
    required this.onContinue,
  });

  final String address;
  final VoidCallback onTapAddressChip;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          18,
          16,
          MediaQuery.paddingOf(context).bottom + 18,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          boxShadow: [
            BoxShadow(
              offset: Offset(0, -4),
              blurRadius: 24,
              color: Color(0x1F000000),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onTapAddressChip,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(AppIcons.truck, width: 20, height: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        address.isEmpty ? 'Joy tanlanmadi' : address,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.30,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: MaterialButton(
                onPressed: address.isEmpty ? null : onContinue,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                color: AppColor.blueMain,
                disabledColor: AppColor.blueMain.withValues(alpha: 0.5),
                textColor: Colors.white,
                elevation: 0,
                highlightElevation: 0,
                child: const Text(
                  'Davom ettirish',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListModeSheet extends StatelessWidget {
  const _ListModeSheet({
    required this.searchController,
    required this.state,
    required this.onSearchChanged,
    required this.onUseMyLocation,
    required this.onSuggestionTap,
    required this.onClose,
    required this.onConfirm,
  });

  final TextEditingController searchController;
  final MapState state;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onUseMyLocation;
  final ValueChanged<LocationData> onSuggestionTap;
  final VoidCallback onClose;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          color: Colors.black54,
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(maxHeight: size.height * 0.75),
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.paddingOf(context).bottom + 16,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColor.lightGrey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF3F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Manzilni kiriting',
                        border: InputBorder.none,
                        icon: SvgPicture.asset(AppIcons.location, width: 18, height: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: onUseMyLocation,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          Icon(Icons.my_location, color: AppColor.blueMain),
                          const SizedBox(width: 12),
                          const Text(
                            'Mening joylashuvim',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: _SuggestionsList(
                      state: state,
                      onTap: onSuggestionTap,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: MaterialButton(
                      onPressed: state.selectedAddress.isEmpty ? null : onConfirm,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      color: AppColor.blueMain,
                      disabledColor: AppColor.blueMain.withValues(alpha: 0.5),
                      textColor: Colors.white,
                      elevation: 0,
                      highlightElevation: 0,
                      child: const Text(
                        'Tanlash',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionsList extends StatelessWidget {
  const _SuggestionsList({required this.state, required this.onTap});

  final MapState state;
  final ValueChanged<LocationData> onTap;

  @override
  Widget build(BuildContext context) {
    if (state.locationsStatus == MapStatus.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (state.suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Manzilni kiriting yoki "Mening joylashuvim" ni tanlang',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColor.grey, fontSize: 14),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: state.suggestions.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 32),
      itemBuilder: (context, index) {
        final loc = state.suggestions[index];
        return InkWell(
          onTap: () => onTap(loc),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                SvgPicture.asset(AppIcons.location, width: 18, height: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    loc.formatted,
                    style: const TextStyle(fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

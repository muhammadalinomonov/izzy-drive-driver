import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/location_service.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/core/services/websocket_service.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_image.dart';
import 'package:taxi_app/src/features/master/data/repository/master_repository_impl.dart';
import 'package:taxi_app/src/features/master/data/source/master_remote_data_source.dart';
import 'package:taxi_app/src/features/master/presentation/bloc/master_bloc.dart';
import 'package:taxi_app/src/features/master/presentation/screens/master_detail_sheet.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/bloc/orders_bloc.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/arrived_sheet.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/beuty_widget.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/in_progress_sheet.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/order_status_row.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/sub_order_proposal_sheet.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/tracking_sheet.dart';
import 'package:taxi_app/src/features/profile/domain/entities/map_entity.dart';
import 'package:taxi_app/src/routes/pages.dart';

class OrderSingleScreen extends StatefulWidget {
  const OrderSingleScreen({super.key});

  @override
  State<OrderSingleScreen> createState() => _OrderSingleScreenState();
}

class _OrderSingleScreenState extends State<OrderSingleScreen> with WidgetsBindingObserver {
  static const _resumeDebounce = Duration(seconds: 10);
  DateTime? _lastResumeRefresh;

  late mapbox.MapboxMap _mapboxMap;
  mapbox.PolylineAnnotationManager? _polylineAnnotationManager;
  mapbox.PointAnnotationManager? _pointAnnotationManager;

  // Separate tracked annotations so we can update only the mechanic marker
  // without touching the static destination marker.
  mapbox.PointAnnotation? _mechanicAnnotation;
  mapbox.PointAnnotation? _destinationAnnotation;

  Uint8List? _mechanicMarkerPng;
  Uint8List? _destinationMarkerPng;

  bool _mapReady = false;

  // Insets used for cameraForCoordinateBounds — bottom matches the sheet height.
  static final _mapPadding = mapbox.MbxEdgeInsets(
    top: 90,
    left: 50,
    bottom: 200,
    right: 50,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<OrdersBloc>()
      ..add(GetCurrentOrderEvent())
      ..add(ConnectToWebSocketEvent());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final now = DateTime.now();
    if (_lastResumeRefresh != null && now.difference(_lastResumeRefresh!) < _resumeDebounce) {
      return;
    }
    _lastResumeRefresh = now;
    serviceLocator<WebSocketService>().reconnect();
    if (!mounted) return;
    // Silent refresh: the order tracking UI is already populated, so we don't
    // want to collapse it into a shimmer just because the app resumed.
    context.read<OrdersBloc>().add(GetCurrentOrderEvent(silent: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          BlocListener<OrdersBloc, OrdersState>(
            listenWhen: (p, c) => p.lifecycleEvent != c.lifecycleEvent,
            listener: (context, state) {
              if (state.lifecycleEvent == OrderLifecycleEvent.completed) {
                context.read<OrdersBloc>().add(ClearLifecycleEventEvent());
                context.pushReplacement(Pages.finishedOrder);
              }
            },
          ),
          BlocListener<OrdersBloc, OrdersState>(
            listenWhen: (p, c) => p.pendingSubOrder != c.pendingSubOrder,
            listener: (context, state) {
              final pending = state.pendingSubOrder;
              if (pending != null) SubOrderProposalSheet.show(context, pending);
            },
          ),
          // Mechanic live position — update only the mechanic marker.
          BlocListener<OrdersBloc, OrdersState>(
            listenWhen: (p, c) =>
                p.mechanicLat != c.mechanicLat || p.mechanicLng != c.mechanicLng,
            listener: (context, state) {
              final lat = state.mechanicLat;
              final lng = state.mechanicLng;
              if (lat == null || lng == null || !_mapReady) return;
              _updateMechanicMarker(lat, lng);
            },
          ),
          // Route changed — redraw everything.
          BlocListener<OrdersBloc, OrdersState>(
            listenWhen: (p, c) => p.currentOrder.map != c.currentOrder.map,
            listener: (context, state) {
              if (_mapReady) _drawRoute(state.currentOrder.map);
            },
          ),
          BlocListener<OrdersBloc, OrdersState>(
            listenWhen: (p, c) => p is! OrderCanceled && c is OrderCanceled,
            listener: (context, state) {
              if (context.mounted) context.go(Pages.main);
            },
          ),
        ],
        child: BlocConsumer<OrdersBloc, OrdersState>(
          listenWhen: (previous, current) => previous.currentOrder != current.currentOrder,
          listener: (context, state) {
            if (state.currentOrder.status.isMechanicDone) {
              context.pushReplacement(Pages.finishedOrder);
            }
          },
          builder: (context, state) {
            if (state.currentOrderStatus.isSuccess) {
              final status = state.currentOrder.status;
              return Stack(
                children: [
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
                            state.currentOrder.currentAddress.longitude,
                            state.currentOrder.currentAddress.latitude,
                          ),
                        ),
                        zoom: 14.5,
                        pitch: 0.0,
                        bearing: 0.0,
                      ),
                    ),
                  ),

                  // mechanicSelected — searching animation
                  if (status.isMechanicSelected) ...[
                    BeautifulRadiationWidget(
                      isVisible: true,
                      position: Offset(
                        MediaQuery.of(context).size.width / 2,
                        MediaQuery.of(context).size.height / 2,
                      ),
                    ),
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
                                'Waiting for the master to accept the order...',
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
                                'A driver is usually found within 1 minute (30 seconds)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () => _confirmCancel(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]

                  else if (status.isAccepted)
                    const Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: TrackingSheet(),
                    )

                  else if (status.isArrived)
                    const Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: ArrivedSheet(),
                    )

                  else if (status.isInProgress)
                    const Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: InProgressSheet(),
                    )

                  else
                    Positioned(
                      bottom: 0, right: 0, left: 0,
                      child: Container(
                        padding: const EdgeInsets.only(top: 12, bottom: 24),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          color: AppColor.white,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(height: 4, width: 42, color: AppColor.grey2),
                            const SizedBox(height: 20),
                            Text(
                              state.currentOrder.status.orderDescription,
                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                fontSize: 20, fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 42),
                              child: OrderStatusRow(),
                            ),
                            const SizedBox(height: 40),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 14),
                                child: Text(
                                  'Master',
                                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    fontWeight: FontWeight.w600, fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Row(
                                children: [
                                  AvatarImage(
                                    imageUrl: state.currentOrder.selectedMechanic.photo,
                                    size: 44,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    state.currentOrder.selectedMechanic.fullName,
                                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                      fontWeight: FontWeight.w600, fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      final bloc = MasterBloc(
                                        MasterRepositoryImpl(MasterRemoteDataSource()),
                                        LocationService(),
                                      );
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (ctx) => BlocProvider.value(
                                          value: bloc,
                                          child: MasterDetailSheet(
                                            id: state.currentOrder.selectedMechanic.id,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 6),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        color: AppColor.lightBlue,
                                      ),
                                      child: Text(
                                        'More',
                                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                          fontWeight: FontWeight.w500, fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Back button
                  Positioned(
                    top: 50,
                    left: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () {
                          context.read<OrdersBloc>().add(DisConnectFromWebSocketEvent());
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(Pages.main);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              );
            } else if (state.currentOrderStatus.isInProgress) {
              return const Center(child: CircularProgressIndicator());
            } else if (state.currentOrderStatus.isFailure) {
              return const Center(child: Text('Error'));
            } else {
              return const Center(child: Text('No current order'));
            }
          },
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final bloc = context.read<OrdersBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel order?'),
        content: const Text('Are you sure you want to cancel the order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    context.go(Pages.main);
    bloc.add(CancelOrderEvent());
  }

  /// Redraw polyline + both markers from fresh MapEntity.
  /// Clears any previously drawn annotations before drawing new ones.
  void _drawRoute(MapEntity map) async {
    if (_polylineAnnotationManager == null || _pointAnnotationManager == null) return;
    try {
      // Clear polyline
      await _polylineAnnotationManager!.deleteAll();

      // Clear tracked point annotations
      if (_destinationAnnotation != null) {
        await _pointAnnotationManager!.delete(_destinationAnnotation!);
        _destinationAnnotation = null;
      }
      if (_mechanicAnnotation != null) {
        await _pointAnnotationManager!.delete(_mechanicAnnotation!);
        _mechanicAnnotation = null;
      }

      // Draw polyline if route has enough points
      if (map.route.length >= 2) {
        final positions = map.route.map((p) => mapbox.Position(p.lng, p.lat)).toList();
        await _polylineAnnotationManager!.create(
          mapbox.PolylineAnnotationOptions(
            geometry: mapbox.LineString(coordinates: positions),
            lineColor: 0xFF2563EB,
            lineWidth: 4.0,
          ),
        );
      }

      // Destination marker — driver's order address (endPoint)
      if (map.endPoint.lat != 0 || map.endPoint.lng != 0) {
        _destinationAnnotation = await _pointAnnotationManager!.create(
          mapbox.PointAnnotationOptions(
            geometry: map.endPoint.toPoint(),
            image: _destinationMarkerPng,
            iconSize: 2,
          ),
        );
      }

      // Mechanic marker — mechanic's position at acceptance time (startPoint)
      if (map.startPoint.lat != 0 || map.startPoint.lng != 0) {
        _mechanicAnnotation = await _pointAnnotationManager!.create(
          mapbox.PointAnnotationOptions(
            geometry: map.startPoint.toPoint(),
            image: _mechanicMarkerPng,
            iconSize: 0.4,
          ),
        );
      }

      await _fitCameraToBounds(
        lat1: map.startPoint.lat, lng1: map.startPoint.lng,
        lat2: map.endPoint.lat, lng2: map.endPoint.lng,
      );
    } catch (e) {
      debugPrint('Error drawing route: $e');
    }
  }

  /// Update only the mechanic marker — destination stays fixed.
  /// Refits the camera so both points remain visible.
  void _updateMechanicMarker(double lat, double lng) async {
    if (_pointAnnotationManager == null || !mounted) return;
    final endPoint = context.read<OrdersBloc>().state.currentOrder.map.endPoint;
    try {
      if (_mechanicAnnotation != null) {
        await _pointAnnotationManager!.delete(_mechanicAnnotation!);
      }
      _mechanicAnnotation = await _pointAnnotationManager!.create(
        mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(coordinates: mapbox.Position(lng, lat)),
          image: _mechanicMarkerPng,
          iconSize: 0.6,
        ),
      );

      if (endPoint.lat != 0 || endPoint.lng != 0) {
        final camera = await _buildBoundsCamera(
          lat1: lat, lng1: lng,
          lat2: endPoint.lat, lng2: endPoint.lng,
        );
        await _mapboxMap.flyTo(camera, mapbox.MapAnimationOptions(duration: 600));
      }
    } catch (e) {
      debugPrint('Error updating mechanic marker: $e');
    }
  }

  void _onMapCreated(mapbox.MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    final bloc = mounted ? context.read<OrdersBloc>() : null;
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _polylineAnnotationManager =
          await _mapboxMap.annotations.createPolylineAnnotationManager();
      _pointAnnotationManager =
          await _mapboxMap.annotations.createPointAnnotationManager();

      _mechanicMarkerPng = (await rootBundle.load('assets/icons/mastericon.png')).buffer.asUint8List();
      _destinationMarkerPng = (await rootBundle.load('assets/images/to_marker.png')).buffer.asUint8List();

      if (!mounted) return;
      setState(() => _mapReady = true);

      final state = bloc?.state;
      if (state != null) {
        final map = state.currentOrder.map;
        if (map.route.isNotEmpty || map.endPoint.lat != 0 || map.startPoint.lat != 0) {
          _drawRoute(map);
        } else {
          await _centerOnAddress(state.currentOrder.currentAddress);
        }
      }
    } catch (e) {
      debugPrint('Error in map creation: $e');
    }
  }

  /// Use Mapbox's own bounds-fitting algorithm to zoom correctly.
  Future<void> _fitCameraToBounds({
    required double lat1, required double lng1,
    required double lat2, required double lng2,
  }) async {
    final hasFirst = lat1 != 0 || lng1 != 0;
    final hasSecond = lat2 != 0 || lng2 != 0;

    if (!hasFirst && !hasSecond) return;

    if (hasFirst && hasSecond) {
      final camera = await _buildBoundsCamera(
        lat1: lat1, lng1: lng1, lat2: lat2, lng2: lng2,
      );
      await _mapboxMap.setCamera(camera);
    } else {
      final lat = hasFirst ? lat1 : lat2;
      final lng = hasFirst ? lng1 : lng2;
      await _mapboxMap.setCamera(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: mapbox.Position(lng, lat)),
          zoom: 15.0,
          pitch: 0.0,
          bearing: 0.0,
        ),
      );
    }
  }

  /// Calculate camera options that fit both coordinates with padding.
  Future<mapbox.CameraOptions> _buildBoundsCamera({
    required double lat1, required double lng1,
    required double lat2, required double lng2,
  }) {
    final minLat = min(lat1, lat2);
    final maxLat = max(lat1, lat2);
    final minLng = min(lng1, lng2);
    final maxLng = max(lng1, lng2);

    final bounds = mapbox.CoordinateBounds(
      southwest: mapbox.Point(coordinates: mapbox.Position(minLng, minLat)),
      northeast: mapbox.Point(coordinates: mapbox.Position(maxLng, maxLat)),
      infiniteBounds: false,
    );

    return _mapboxMap.cameraForCoordinateBounds(
      bounds, _mapPadding, null, null, null, null,
    );
  }

  /// Fallback: center map on order address when no route data is available.
  Future<void> _centerOnAddress(dynamic address) async {
    try {
      final lat = address.latitude as double;
      final lng = address.longitude as double;
      if (lat == 0 && lng == 0) return;
      await _mapboxMap.setCamera(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: mapbox.Position(lng, lat)),
          zoom: 14.5,
          pitch: 0.0,
          bearing: 0.0,
        ),
      );
    } catch (e) {
      debugPrint('Error centering on address: $e');
    }
  }
}

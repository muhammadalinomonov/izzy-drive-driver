import 'package:flutter/material.dart';
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
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/beuty_widget.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/order_actions_widget.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/order_status_row.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/sub_order_proposal_sheet.dart';
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
  bool _mapReady = false;
  mapbox.Position startPosition = mapbox.Position(69.2047, 41.2806);
  mapbox.Position endPosition = mapbox.Position(69.2056, 41.2789);

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
    // Force a fresh socket — iOS often suspends the WS during background
    // without firing onDone, so the cached _isConnected can be a lie.
    serviceLocator<WebSocketService>().reconnect();
    if (!mounted) return;
    context.read<OrdersBloc>().add(GetCurrentOrderEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          // Lifecycle events from WS — drive navigation/UI side effects.
          BlocListener<OrdersBloc, OrdersState>(
            listenWhen: (p, c) => p.lifecycleEvent != c.lifecycleEvent,
            listener: (context, state) {
              if (state.lifecycleEvent == OrderLifecycleEvent.completed) {
                context.read<OrdersBloc>().add(ClearLifecycleEventEvent());
                context.pushReplacement(Pages.finishedOrder);
              }
            },
          ),
          // Mechanic proposed extra work — show modal.
          BlocListener<OrdersBloc, OrdersState>(
            listenWhen: (p, c) => p.pendingSubOrder != c.pendingSubOrder,
            listener: (context, state) {
              final pending = state.pendingSubOrder;
              if (pending != null) {
                SubOrderProposalSheet.show(context, pending);
              }
            },
          ),
          // Mechanic live position from `new-mechanic-address` — recenter map.
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
          // Cancellation — broadcast or self-cancel — pop back to main.
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
            return Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + (MediaQuery.of(context).size.height * 0.3),
                  ),
                  child: mapbox.MapWidget(
                    key: const ValueKey('beautifulPulseMapWidget'),
                    styleUri: mapbox.MapboxStyles.MAPBOX_STREETS,
                    onMapCreated: _onMapCreated,
                    cameraOptions: mapbox.CameraOptions(
                      center: mapbox.Point(
                        coordinates: mapbox.Position(
                          state.currentOrder.currentAddress.latitude,
                          state.currentOrder.currentAddress.longitude,
                        ),
                      ),
                      zoom: 14.5,
                      pitch: 0.0,
                      bearing: 0.0,
                    ),
                    onCameraChangeListener: (cameraChanged) {
                      // setState(() => isScrolling = true);
                      // _debounceTimer?.cancel();
                      // _debounceTimer = Timer(const Duration(milliseconds: 400), () {
                      //   if (mounted) {
                      //     setState(() => isScrolling = false);
                      //     if (hasArrived && !isScrolling) _updateRadiationPosition();
                      //   }
                      // });
                    },
                  ),
                ),
                if (state.currentOrder.status.isMechanicSelected)
                  BeautifulRadiationWidget(
                    isVisible: true,
                    position: Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2),
                  ),
                if (state.currentOrder.status.isMechanicSelected)
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
                              style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => _confirmCancel(context),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  )
                else
                  Positioned(
                    bottom: 0,
                    right: 0,
                    left: 0,
                    child: Container(
                      padding: EdgeInsets.only(top: 12, bottom: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        color: AppColor.white,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(height: 4, width: 42, color: AppColor.grey2),
                          SizedBox(height: 20),
                          Text(
                            state.currentOrder.status.orderDescription,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge!.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24),

                          Padding(padding: EdgeInsets.symmetric(horizontal: 42), child: OrderStatusRow()),
                          SizedBox(height: 40),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(left: 14),
                              child: Text(
                                'Master',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                AvatarImage(
                                  imageUrl: state.currentOrder.selectedMechanic.photo,
                                  size: 44,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  state.currentOrder.selectedMechanic.fullName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    final bloc = MasterBloc(
                                      MasterRepositoryImpl(MasterRemoteDataSource()),
                                      LocationService(),
                                    );

                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (context) => BlocProvider.value(
                                        value: bloc,
                                        child: MasterDetailSheet(id: state.currentOrder.selectedMechanic.id),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color: AppColor.lightBlue,
                                    ),
                                    child: Text(
                                      'More',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w500, fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 32),
                          OrderActionsWidget(),
                        ],
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
            return Center(child: Text('Error'));
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
    if (confirmed != true || !mounted) return;
    bloc.add(CancelOrderEvent());
    if (!mounted) return;
    context.go(Pages.main);
  }

  /// Update mechanic marker at given lat/lng and recenter the camera.
  /// Called from the `mechanicLat/Lng` BlocListener — driven by the
  /// `new-mechanic-address` WS event for real-time tracking.
  void _updateMechanicMarker(double lat, double lng) async {
    if (_pointAnnotationManager == null) return;
    try {
      await _pointAnnotationManager!.deleteAll();
      await _pointAnnotationManager!.create(
        mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(coordinates: mapbox.Position(lng, lat)),
          iconSize: 1.0,
        ),
      );
      await _mapboxMap.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: mapbox.Position(lng, lat)),
          zoom: 15.5,
        ),
        mapbox.MapAnimationOptions(duration: 800),
      );
    } catch (e) {
      print('Error updating mechanic marker: $e');
    }
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
}

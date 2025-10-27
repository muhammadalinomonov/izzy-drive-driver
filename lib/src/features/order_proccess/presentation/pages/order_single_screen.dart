import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/location_service.dart';
import 'package:taxi_app/src/features/master/data/repository/master_repository_impl.dart';
import 'package:taxi_app/src/features/master/data/source/master_remote_data_source.dart';
import 'package:taxi_app/src/features/master/presentation/bloc/master_bloc.dart';
import 'package:taxi_app/src/features/master/presentation/screens/master_detail_sheet.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/bloc/orders_bloc.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/beuty_widget.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/order_actions_widget.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/order_status_row.dart';
import 'package:taxi_app/src/routes/pages.dart';

class OrderSingleScreen extends StatefulWidget {
  const OrderSingleScreen({super.key});

  @override
  State<OrderSingleScreen> createState() => _OrderSingleScreenState();
}

class _OrderSingleScreenState extends State<OrderSingleScreen> {
  late mapbox.MapboxMap _mapboxMap;
  mapbox.PolylineAnnotationManager? _polylineAnnotationManager;
  mapbox.PointAnnotationManager? _pointAnnotationManager;
  bool _mapReady = false;
  mapbox.Position startPosition = mapbox.Position(69.2047, 41.2806);
  mapbox.Position endPosition = mapbox.Position(69.2056, 41.2789);

  @override
  void initState() {
    super.initState();
    context.read<OrdersBloc>()
      ..add(GetCurrentOrderEvent())
      ..add(ConnectToWebSocketEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<OrdersBloc, OrdersState>(
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
                              'Odatda haydovchi 1 daqiqa ichida topiladi (30 soniya)',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                // context.read<OrdersBloc>().add(DisConnectFromWebSocketEvent());
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
                                if (state.currentOrder.selectedMechanic.photo.isNotEmpty)
                                  Image.network(
                                    state.currentOrder.selectedMechanic.photo,
                                    width: 44,
                                    height: 44,
                                    errorBuilder: (context, error, stackTrace) => SizedBox(),
                                  ),
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
                        Navigator.of(context).pop();
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
    );
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

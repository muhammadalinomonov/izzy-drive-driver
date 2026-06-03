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
import 'package:taxi_app/src/core/utils/adaptive_poller.dart';
import 'package:taxi_app/src/features/cancel_reasons/presentation/widgets/cancel_reason_sheet.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_image.dart';
import 'package:taxi_app/src/features/master/data/repository/master_repository_impl.dart';
import 'package:taxi_app/src/features/master/data/source/master_remote_data_source.dart';
import 'package:taxi_app/src/features/master/presentation/bloc/master_bloc.dart';
import 'package:taxi_app/src/features/master/presentation/screens/master_detail_sheet.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/bloc/orders_bloc.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/arrived_sheet.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/awaiting_mechanic_sheet.dart';
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
  late final AdaptivePoller _poller;

  late mapbox.MapboxMap _mapboxMap;
  mapbox.PolylineAnnotationManager? _polylineAnnotationManager;
  mapbox.PointAnnotationManager? _pointAnnotationManager;
  // Arrived / in_progress vaziyatda mexanik atrofidagi ko'k pulse halqalar.
  mapbox.CircleAnnotationManager? _circleAnnotationManager;

  // Separate tracked annotations so we can update only the mechanic marker
  // without touching the static destination marker.
  mapbox.PointAnnotation? _mechanicAnnotation;
  mapbox.PointAnnotation? _destinationAnnotation;
  final List<mapbox.CircleAnnotation> _pulseAnnotations = [];

  Uint8List? _mechanicMarkerPng;
  Uint8List? _destinationMarkerPng;

  bool _mapReady = false;
  // True while `_drawRoute` is mid-flight (clearAnnotations → create cycle).
  // `_updateMechanicMarker` skips while this is set so live-position updates
  // can't race with the redraw and leave a duplicate marker on the map.
  bool _drawingRoute = false;
  // Latch: order tugagandan keyin pushReplacement IKKI joydan
  // (lifecycleEvent.completed listener + currentOrder.status.isMechanicDone
  // listener) chaqirilardi va keyingi state emissionlarda yana ham qayta
  // ishlardi → finished screen'ga ko'p marta yo'naltirilardi. Bitta marta
  // chaqirilishini kafolatlaymiz.
  bool _navigatedToFinished = false;
  // Camera-fitni faqat status almashganda qilaymiz. WS dan har mexanik
  // position update kelganda yoki polling refresh paytida `_drawRoute`
  // qaytadan ishga tushadi — lekin foydalanuvchi zoom qilgan bo'lsa, qayta
  // fit qilmasdan saqlaymiz.
  String? _lastFittedStatusKey;

  // Bottom padding kichikroq → markerlar sheet bilan to'qnashmaydi, lekin
  // ikki marker (mexanik + manzil) bir-biriga juda yaqin qisilmaydi va
  // accepted state'da zoom biroz yaqinroq chiqadi.
  static final _mapPadding = mapbox.MbxEdgeInsets(
    top: 100,
    left: 60,
    bottom: 320,
    right: 60,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<OrdersBloc>()
      ..add(GetCurrentOrderEvent())
      ..add(ConnectToWebSocketEvent());
    // WS uzilgan vaziyatlar uchun backup polling - silent fetch UI'ni
    // o'zgartirmaydi, tracking sheet o'z holatida qoladi.
    _poller = AdaptivePoller(
      ws: serviceLocator<WebSocketService>(),
      onPoll: () {
        if (!mounted) return;
        context.read<OrdersBloc>().add(GetCurrentOrderEvent(silent: true));
      },
    )..start();
  }

  @override
  void dispose() {
    _poller.dispose();
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
    return PopScope(
      // Back doim main'ga olib boradi (offers list yoki order_create'ga
      // emas) - foydalanuvchi qaerdan kelganidan qat'i nazar, tracking
      // screen'dan chiqsa kerakli joyga tushadi.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && context.mounted) context.go(Pages.main);
      },
      child: Scaffold(
      body: MultiBlocListener(
        listeners: [
          BlocListener<OrdersBloc, OrdersState>(
            listenWhen: (p, c) => p.lifecycleEvent != c.lifecycleEvent,
            listener: (context, state) {
              if (_navigatedToFinished) return;
              if (state.lifecycleEvent == OrderLifecycleEvent.completed) {
                _navigatedToFinished = true;
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
          // Mechanic live position - update only the mechanic marker.
          // _drawRoute paytida o'tkazib yuboriladi (aks holda 0.4 va 0.6
          // o'lchamli ikki marker bir vaqtda paydo bo'lardi — _drawRoute'ning
          // clearAnnotations → wait → create oralig'ida _updateMechanicMarker
          // race qilardi).
          BlocListener<OrdersBloc, OrdersState>(
            listenWhen: (p, c) =>
                p.mechanicLat != c.mechanicLat || p.mechanicLng != c.mechanicLng,
            listener: (context, state) {
              final lat = state.mechanicLat;
              final lng = state.mechanicLng;
              if (lat == null || lng == null || !_mapReady) return;
              if (_drawingRoute) return;
              _updateMechanicMarker(lat, lng);
            },
          ),
          // Map yoki status o'zgarishi — bir listenerda birlashtirilgan, aks
          // holda har ikkala field bir vaqtda o'zgarganda _drawRoute IKKI
          // marta concurrent ishlardi va annotation duplikatlari paydo
          // bo'lardi (mechanicSelected → accepted o'tishida bug edi).
          BlocListener<OrdersBloc, OrdersState>(
            listenWhen: (p, c) =>
                p.currentOrder.map != c.currentOrder.map ||
                p.currentOrder.status != c.currentOrder.status,
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
          // Mexanik orderni rad etganda backend status'ni 'new' (pending) ga
          // qaytaradi va `mechanic-cancelled-research` WS event yuboradi.
          // OrdersBloc shu eventda silent refresh qiladi - status pending
          // bo'lib qoladi. Faqat mechanicSelected → pending transitionida
          // driverni offers ekraniga qaytaramiz; aks holda boshqa pending
          // holatlarda ham false-positive nav bo'lib qolardi.
          BlocListener<OrdersBloc, OrdersState>(
            listenWhen: (p, c) =>
                p.currentOrder.status.isMechanicSelected &&
                c.currentOrder.status.isPending,
            listener: (context, state) {
              if (context.mounted) context.go(Pages.invatesPage);
            },
          ),
        ],
        child: BlocConsumer<OrdersBloc, OrdersState>(
          // Status mechanicDone'ga TUSHGAN paytda navigate; keyingi
          // currentOrder field o'zgarishlarida (mechanic position update)
          // qayta fire bo'lmasligi uchun aniq transition tekshiruvi.
          listenWhen: (previous, current) =>
              !previous.currentOrder.status.isMechanicDone &&
              current.currentOrder.status.isMechanicDone,
          listener: (context, state) {
            if (_navigatedToFinished) return;
            _navigatedToFinished = true;
            context.pushReplacement(Pages.finishedOrder);
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
                    // Mexanik javobini kutgan paytda map non-interactive bo'ladi
                    // - har ikkala marker ham allaqachon ko'rinib turibdi.
                    child: IgnorePointer(
                      ignoring: status.isMechanicSelected,
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
                  ),

                  // mechanicSelected - chiroyli kutish sheet (map ustida
                  // markaziy spinner yo'q, hammasi sheet ichida).
                  if (status.isMechanicSelected)
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: AwaitingMechanicSheetConnector(
                        onCancel: () => _confirmCancel(context),
                      ),
                    )

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
                                    name: state.currentOrder.selectedMechanic.fullName,
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
                          // Back qilish active orderni bekor qilmaydi — WS
                          // hayotda qoladi, MainScreen/HomeScreen WS event-
                          // larini olishi davom etadi. Disconnect faqat
                          // logout / cancel oqimlarida bo'lishi kerak.
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(Pages.main);
                          }
                        },
                      ),
                    ),
                  ),

                  // Recenter button — Stack'ning ENG OXIRIDA, sheet'lardan
                  // KEYIN turishi shart, aks holda u sheet ostida qoladi.
                  // O'ng tomon, sheet yuqorisida (~30% balandlik + safe-area
                  // + 16px gap).
                  if (!status.isMechanicSelected)
                    Positioned(
                      right: 16,
                      // Sheet'ning real balandligi ~50% atrofida (figma'ga
                      // qarab) — map'ning 30% padding'idan kattaroq. Tugma
                      // sheet'ning yuqori chetidan ~16px tepada turishi
                      // uchun 0.52 + 16 ishlatamiz.
                      bottom: MediaQuery.paddingOf(context).bottom +
                          MediaQuery.sizeOf(context).height * 0.5 +
                          16,
                      child: _MapRecenterButton(onTap: _recenterMap),
                    ),
                ],
              );
            } else if (state.currentOrderStatus.isInProgress) {
              return const _OrderSingleSkeleton();
            } else if (state.currentOrderStatus.isFailure) {
              return const Center(child: Text('Error'));
            } else {
              return const _OrderSingleSkeleton();
            }
          },
        ),
      ),
    ),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final bloc = context.read<OrdersBloc>();
    final choice = await showCancelReasonSheet(context);
    if (choice == null || !context.mounted) return;
    context.go(Pages.main);
    bloc.add(CancelOrderEvent(
      reasonId: choice.reasonId,
      reasonText: choice.customText,
    ));
  }

  /// Redraw polyline + markers from fresh MapEntity. Status'ga qarab ikki
  /// xil vizual:
  ///  - accepted (yo'lda): polyline + 2 ta marker (mexanik + manzil)
  ///  - arrived / in_progress: bitta nuqta + atrofida ko'k pulse halqalari
  ///    (Figma 1897:4828)
  void _drawRoute(MapEntity map) async {
    if (_polylineAnnotationManager == null || _pointAnnotationManager == null) return;
    // Concurrent _drawRoute call'larini ham, _updateMechanicMarker race'ini
    // ham bloklaymiz — annotation manager'da bir vaqtda faqat bitta mutation
    // pipeline ishlasin.
    if (_drawingRoute) return;
    _drawingRoute = true;
    try {
      await _clearMapAnnotations();

      if (!mounted) return;
      final status = context.read<OrdersBloc>().state.currentOrder.status;
      final atSinglePoint = status.isArrived || status.isInProgress;

      // Status almashganida YANGI fit-camera kerak; aks holda foydalanuvchi
      // zoom qilgan bo'lsa shunday qoladi (recenter button bilan qaytarib
      // beradi). Bu polling refresh / WS position update sayin zoom o'z
      // holatiga "tortib qaytishi" muammosini hal qiladi.
      final statusKey = status.toString();
      final shouldFit = _lastFittedStatusKey != statusKey;

      if (atSinglePoint) {
        // Mexanik allaqachon haydovchining manzilida - bitta nuqta yetadi.
        await _drawPulseMarker(
          map.endPoint.lat,
          map.endPoint.lng,
          fitCamera: shouldFit,
        );
        if (shouldFit) _lastFittedStatusKey = statusKey;
        return;
      }

      // accepted: yo'l chizig'i + 2 marker.
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
      if (map.endPoint.lat != 0 || map.endPoint.lng != 0) {
        _destinationAnnotation = await _pointAnnotationManager!.create(
          mapbox.PointAnnotationOptions(
            geometry: map.endPoint.toPoint(),
            image: _destinationMarkerPng,
            iconSize: 2,
          ),
        );
      }
      if (map.startPoint.lat != 0 || map.startPoint.lng != 0) {
        _mechanicAnnotation = await _pointAnnotationManager!.create(
          mapbox.PointAnnotationOptions(
            geometry: map.startPoint.toPoint(),
            image: _mechanicMarkerPng,
            iconSize: 0.4,
          ),
        );
      }
      // Fit faqat status transition'da; polling refresh paytida foydalanuvchi
      // zoomida qoladi (recenter button mavjud — istasa qaytaradi).
      if (shouldFit) {
        await _fitCameraToBounds(
          lat1: map.startPoint.lat, lng1: map.startPoint.lng,
          lat2: map.endPoint.lat, lng2: map.endPoint.lng,
        );
        _lastFittedStatusKey = statusKey;
      }
    } catch (e) {
      debugPrint('Error drawing route: $e');
    } finally {
      _drawingRoute = false;
    }
  }

  /// Barcha annotation'larni tozalash - status o'zgarganda har xil
  /// stildagi marker'lar bir-biriga yopishib qolmasligi uchun.
  Future<void> _clearMapAnnotations() async {
    await _polylineAnnotationManager?.deleteAll();
    if (_destinationAnnotation != null) {
      await _pointAnnotationManager!.delete(_destinationAnnotation!);
      _destinationAnnotation = null;
    }
    if (_mechanicAnnotation != null) {
      await _pointAnnotationManager!.delete(_mechanicAnnotation!);
      _mechanicAnnotation = null;
    }
    if (_pulseAnnotations.isNotEmpty && _circleAnnotationManager != null) {
      for (final c in _pulseAnnotations) {
        await _circleAnnotationManager!.delete(c);
      }
      _pulseAnnotations.clear();
    }
  }

  /// Figma 1897:4828 - bitta nuqta atrofida ikkita ko'k translucent halqa
  /// + ustida mexanik ikoni. Yo'l chizig'i va manzil markeri ko'rsatilmaydi.
  ///
  /// [fitCamera] — false bo'lsa kamera holatini saqlaydi (polling refresh,
  /// repeated _drawRoute paytida zoom snap qilmasin). True — initial / status
  /// transition.
  Future<void> _drawPulseMarker(
    double lat,
    double lng, {
    bool fitCamera = true,
  }) async {
    if (lat == 0 && lng == 0) return;
    final point = mapbox.Point(coordinates: mapbox.Position(lng, lat));
    // Tashqi katta translucent halqa.
    final outer = await _circleAnnotationManager?.create(
      mapbox.CircleAnnotationOptions(
        geometry: point,
        circleRadius: 60,
        circleColor: 0xFF0866FF,
        circleOpacity: 0.10,
      ),
    );
    if (outer != null) _pulseAnnotations.add(outer);
    // Ichki kichikroq, biroz quyuqroq halqa.
    final inner = await _circleAnnotationManager?.create(
      mapbox.CircleAnnotationOptions(
        geometry: point,
        circleRadius: 42,
        circleColor: 0xFF0866FF,
        circleOpacity: 0.18,
      ),
    );
    if (inner != null) _pulseAnnotations.add(inner);
    // Mexanik ikoni - markazda (kichikroq qilindi, halqalar ichida ko'rinsin).
    _mechanicAnnotation = await _pointAnnotationManager!.create(
      mapbox.PointAnnotationOptions(
        geometry: point,
        image: _mechanicMarkerPng,
        iconSize: 0.35,
      ),
    );
    // Camera faqat status transition'da yangilanadi — polling refresh paytida
    // foydalanuvchi zoomida qoladi.
    if (fitCamera) {
      await _mapboxMap.flyTo(
        mapbox.CameraOptions(center: point, zoom: 14, pitch: 0, bearing: 0),
        mapbox.MapAnimationOptions(duration: 600),
      );
    }
  }

  /// Update only the mechanic marker - destination stays fixed.
  ///
  /// **Icon o'lchami 0.4** — `_drawRoute` bilan bir xil; updateda flicker yoki
  /// "katta+kichik" duplikat hissi bermaydi.
  ///
  /// **Camera silliq pan qiladi** (1200ms `flyTo`) — mexanik harakatlanganda
  /// kamera ham unga ergashadi. Faqat WS dan kelgan real position update'da
  /// chaqiriladi; polling refresh'da (mechanicLat/Lng o'zgarmaydi)
  /// `_updateMechanicMarker` umuman chaqirilmaydi → polling paytida zoom
  /// o'zgarmaydi.
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
          iconSize: 0.4,
        ),
      );

      if (endPoint.lat != 0 || endPoint.lng != 0) {
        final camera = await _buildBoundsCamera(
          lat1: lat, lng1: lng,
          lat2: endPoint.lat, lng2: endPoint.lng,
        );
        // Long flyTo = silliq pan; har update'da zoom snap qilmaydi.
        await _mapboxMap.flyTo(
          camera,
          mapbox.MapAnimationOptions(duration: 1200),
        );
      }
    } catch (e) {
      debugPrint('Error updating mechanic marker: $e');
    }
  }

  void _onMapCreated(mapbox.MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    final bloc = mounted ? context.read<OrdersBloc>() : null;
    try {
      // Mapbox v10+ default projection — globe (uzoqlashtirilganda Yer
      // sharsifat ko'rinadi). Loyiha uchun har doim flat (mercator) kerak.
      await _mapboxMap.style.setProjection(
        mapbox.StyleProjection(name: mapbox.StyleProjectionName.mercator),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      // Z-order: birinchi yaratilgan pastda turadi. Circle pastda, polyline
      // o'rtada, point (mexanik ikoni) tepada - pulse halqalar ustani
      // tagiga tushadi, ko'k rang ustaning ikoniga "urilmaydi".
      _circleAnnotationManager =
          await _mapboxMap.annotations.createCircleAnnotationManager();
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

  /// Recenter button: foydalanuvchi zoomni xohlagancha o'zgartirgan bo'lsa,
  /// shu tugmani bosib mexanik + manzil markerlari ko'rinadigan dastlabki
  /// fit-bounds vaziyatga qaytarish. Active order map data'sidan foydalanadi;
  /// agar marshrut mavjud bo'lmasa current address atrofiga zoom qiladi.
  Future<void> _recenterMap() async {
    if (!_mapReady) return;
    if (!mounted) return;
    final state = context.read<OrdersBloc>().state;
    final map = state.currentOrder.map;
    try {
      await _mapboxMap.flyTo(
        await _buildRecenterCamera(state),
        mapbox.MapAnimationOptions(duration: 500),
      );
    } catch (_) {
      // flyTo bolnomalanmagan markerlarda fail bo'lishi mumkin — fallback.
      if (map.startPoint.lat != 0 || map.startPoint.lng != 0) {
        await _fitCameraToBounds(
          lat1: map.startPoint.lat, lng1: map.startPoint.lng,
          lat2: map.endPoint.lat, lng2: map.endPoint.lng,
        );
      } else {
        await _centerOnAddress(state.currentOrder.currentAddress);
      }
    }
  }

  Future<mapbox.CameraOptions> _buildRecenterCamera(OrdersState state) async {
    final map = state.currentOrder.map;
    final status = state.currentOrder.status;
    final hasStart = map.startPoint.lat != 0 || map.startPoint.lng != 0;
    final hasEnd = map.endPoint.lat != 0 || map.endPoint.lng != 0;

    // Arrived / in-progress — pulse marker stilida bitta nuqta atrofiga
    // zoom qilamiz (drawPulseMarker bilan bir xil zoom 15).
    if (status.isArrived || status.isInProgress) {
      final lat = hasEnd ? map.endPoint.lat : map.startPoint.lat;
      final lng = hasEnd ? map.endPoint.lng : map.startPoint.lng;
      if (lat != 0 || lng != 0) {
        return mapbox.CameraOptions(
          center: mapbox.Point(coordinates: mapbox.Position(lng, lat)),
          zoom: 15,
          pitch: 0.0,
          bearing: 0.0,
        );
      }
    }

    // Accepted (yo'lda) — yo'l + 2 marker. cameraForCoordinateBounds barchasini
    // ekranga sig'diradi (drawRoute bilan bir xil mantiq).
    if (hasStart && hasEnd) {
      return _buildBoundsCamera(
        lat1: map.startPoint.lat, lng1: map.startPoint.lng,
        lat2: map.endPoint.lat, lng2: map.endPoint.lng,
      );
    }

    // Hech qaysi marker yo'q — current address atrofida zoom.
    final addr = state.currentOrder.currentAddress;
    return mapbox.CameraOptions(
      center: mapbox.Point(
        coordinates: mapbox.Position(addr.longitude, addr.latitude),
      ),
      zoom: 14.5,
      pitch: 0.0,
      bearing: 0.0,
    );
  }
}

/// Map recenter button — pastki-o'ngda turuvchi oq dumaloq tugma, ichida
/// "my_location" piktogrammasi. Bosish bilan kamerani markerlar ko'rinadigan
/// initial fit-bounds holatiga qaytaradi.
class _MapRecenterButton extends StatelessWidget {
  const _MapRecenterButton({required this.onTap});

  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: const Color(0x33000000),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          onTap();
        },
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.my_location_rounded,
            color: Color(0xFF0866FF),
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ---------- Loading skeleton ----------

/// Order single screen yuklanish vaziyati uchun skeleton - success holatining
/// strukturasini taqlid qiladi: yuqorida xira map placeholder, pastda bottom
/// sheet shape'i (drag handle + sarlavha + status row + master row + actions).
/// Markaziy spinner yo'q - buncha shimmer effekti bilan UI silliq tuyuladi.
class _OrderSingleSkeleton extends StatefulWidget {
  const _OrderSingleSkeleton();

  @override
  State<_OrderSingleSkeleton> createState() => _OrderSingleSkeletonState();
}

class _OrderSingleSkeletonState extends State<_OrderSingleSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  static const Color _kBg = Color(0xFFEFF3F6);
  static const Color _kBgDark = Color(0xFFE3E8EB);

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final sheetHeight = size.height * 0.42;
    return Stack(
      children: [
        // Xira map placeholder - success state'da map qaysi joyni egallasa,
        // shu joyda turadi.
        Positioned.fill(
          bottom: sheetHeight,
          child: AnimatedBuilder(
            animation: _shimmer,
            builder: (context, _) {
              final t = _shimmer.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1 + 2 * t, -1),
                    end: Alignment(1 + 2 * t, 1),
                    colors: const [_kBg, _kBgDark, _kBg],
                  ),
                ),
              );
            },
          ),
        ),
        // Bottom sheet skeleton.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 18,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16, 12, 16, 16 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const SizedBox(height: 24),
                  // Title placeholder.
                  Center(child: _shimmerBox(width: 220, height: 22)),
                  const SizedBox(height: 28),
                  // Status row (4 ta krug).
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        4,
                        (_) => _shimmerCircle(size: 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // "Master" label.
                  _shimmerBox(width: 80, height: 14),
                  const SizedBox(height: 12),
                  // Master row.
                  Row(
                    children: [
                      _shimmerCircle(size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _shimmerBox(width: 140, height: 14),
                            const SizedBox(height: 6),
                            _shimmerBox(width: 80, height: 12),
                          ],
                        ),
                      ),
                      _shimmerBox(width: 70, height: 28, radius: 50),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Actions row (3 ta button).
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _shimmerCircle(size: 48),
                        const SizedBox(width: 24),
                        _shimmerCircle(size: 48),
                        const SizedBox(width: 24),
                        _shimmerCircle(size: 48),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _shimmerBox({required double width, required double height, double radius = 6}) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        final t = _shimmer.value;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * t, 0),
              end: Alignment(1 + 2 * t, 0),
              colors: const [_kBg, _kBgDark, _kBg],
            ),
          ),
        );
      },
    );
  }

  Widget _shimmerCircle({required double size}) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        final t = _shimmer.value;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * t, 0),
              end: Alignment(1 + 2 * t, 0),
              colors: const [_kBg, _kBgDark, _kBg],
            ),
          ),
        );
      },
    );
  }
}

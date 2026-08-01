import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:taxi_app/core/service_locater.dart';
import 'package:taxi_app/core/services/connectivity_service.dart';
import 'package:taxi_app/core/services/websocket_service.dart';
import 'package:taxi_app/features/order_proccess/data/model/sub_order_model.dart';
import 'package:taxi_app/features/order_proccess/domain/entities/current_order_entity.dart';
import 'package:taxi_app/features/order_proccess/domain/order_repo.dart';

import '../../data/model/mechanic_arrived.dart';
import '../../data/model/order_accepted.dart';

part 'orders_event.dart';
part 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrderRepository orderRepository;
  final WebSocketService _ws = serviceLocator<WebSocketService>();
  StreamSubscription<Map<String, dynamic>>? _wsSub;
  StreamSubscription<bool>? _connectivitySub;
  // True when this bloc currently holds a retain on the WebSocketService.
  // Used to avoid double-retain / double-release as the active order
  // appears / disappears.
  bool _wsRetained = false;

  OrdersBloc({required this.orderRepository}) : super(const OrdersState()) {
    on<ConnectToWebSocketEvent>(_onConnectWebSocket);
    on<DisConnectFromWebSocketEvent>(_onDisconnectFromWebSocket);
    on<_WsMessageReceivedEvent>(_onWsMessage);
    on<CancelOrderEvent>(_onCancelOrder);
    on<GetCurrentOrderEvent>(_onGetCurrentOrder);
    on<ChangeSubOrderStatusEvent>(_onChangeSubOrderStatus);
    on<DoneCurrentOrderEvent>(_onDoneCurrentOrder);
    on<RateMasterEvent>(_onRateMaster);
    on<ClearLifecycleEventEvent>(_onClearLifecycleEvent);
    on<ClearPendingSubOrderEvent>(_onClearPendingSubOrder);
    on<ResetCurrentOrderEvent>((event, emit) {
      emit(const OrderCanceled());
      _syncWsRetention();
    });

    _connectivitySub = serviceLocator<ConnectivityService>().onlineStream.listen((online) {
      // WS service o'zi auto-reconnect qiladi; bizdan biroz turtki yetarli.
      // Eski disconnect+connect cyclini olib tashladik — refcount uni
      // shaffof emas qilardi.
      if (online && _wsRetained) {
        _ws.reconnect();
      }
    });
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    _connectivitySub?.cancel();
    // Bloc closing → o'z retain'ini bo'shatish.
    if (_wsRetained) {
      _ws.disconnect();
      _wsRetained = false;
    }
    return super.close();
  }

  /// Active order bor-yo'qligiga qarab WS retain/release qiladi. State
  /// o'zgartiruvchi har bir handler oxirida chaqirilishi kerak. `currentOrder.id`
  /// > 0 — active order; -1 — order yo'q.
  void _syncWsRetention() {
    final hasActiveOrder = state.currentOrder.id > 0;
    if (hasActiveOrder && !_wsRetained) {
      _ws.connect();
      _wsSub ??= _ws.stream.listen((data) => add(_WsMessageReceivedEvent(data)));
      _wsRetained = true;
    } else if (!hasActiveOrder && _wsRetained) {
      _wsSub?.cancel();
      _wsSub = null;
      _ws.disconnect();
      _wsRetained = false;
    }
  }

  void _onConnectWebSocket(ConnectToWebSocketEvent event, Emitter<OrdersState> emit) {
    // Backward-compat: eski call site'lar (order_single_screen.initState,
    // main_screen) bu eventni dispatch qiladi. Endi haqiqiy retain
    // [_syncWsRetention] orqali state'dan kelib chiqib qaror qilinadi —
    // bu handler shu sababli faqat hozirgi state'ni reconcile qiladi.
    _syncWsRetention();
  }

  void _onDisconnectFromWebSocket(DisConnectFromWebSocketEvent event, Emitter<OrdersState> emit) {
    // Explicit disconnect: state retain'idan qat'i nazar ozod qilamiz.
    if (_wsRetained) {
      _wsSub?.cancel();
      _wsSub = null;
      _ws.disconnect();
      _wsRetained = false;
    }
  }

  void _onWsMessage(_WsMessageReceivedEvent event, Emitter<OrdersState> emit) {
    final data = event.data;
    // Backend uses both `event-status` (hyphen) and `event_status` (underscore)
    // inconsistently - read either to be defensive.
    final rawStatus = data['event-status'] ?? data['event_status'];
    final eventStatus = rawStatus is String ? rawStatus : null;

    switch (eventStatus) {
      // WS push'lar — UI'da allaqachon order ko'rinib turibdi, faqat fresh
      // data swap qilamiz. `silent: true` shimmer chiqishini oldini oladi
      // (aks holda home screen'da o'zidan o'zi skeleton paydo bo'lardi).
      case 'order-accepted-at-mechanic':
        final orderAccepted = OrderAccepted.fromJson(data);
        emit(state.copyWith(orderAccepted: orderAccepted));
        add(GetCurrentOrderEvent(silent: true));
        break;

      case 'mechanic-arrived':
        final mechanicArrived = MechanicArrived.fromJson(data);
        debugPrint('Mechanic arrived: $mechanicArrived');
        emit(state.copyWith(lifecycleEvent: OrderLifecycleEvent.arrived));
        add(GetCurrentOrderEvent(silent: true));
        break;

      case 'mechanic-inprogress':
        emit(state.copyWith(lifecycleEvent: OrderLifecycleEvent.inProgress));
        add(GetCurrentOrderEvent(silent: true));
        break;

      case 'mechanic-done':
        add(GetCurrentOrderEvent(silent: true));
        break;

      case 'order-completed':
        emit(state.copyWith(lifecycleEvent: OrderLifecycleEvent.completed));
        add(GetCurrentOrderEvent(silent: true));
        break;

      case 'new-suborder':
        // Mechanic proposed extra work; surface to driver via Phase 4 modal.
        try {
          final subOrder = SubOrderModel.fromJson(data);
          emit(state.copyWith(pendingSubOrder: subOrder));
        } catch (e) {
          debugPrint('Failed to parse new-suborder: $e');
        }
        break;

      case 'suborder-accepted':
      case 'suborder-cancelled':
        // Driver's response was accepted; silent refresh - UI already
        // shows the order, we just swap in fresh data without shimmer.
        add(GetCurrentOrderEvent(silent: true));
        break;

      case 'update-order-price':
        // Pre-proposal price edit; refresh current order if any.
        add(GetCurrentOrderEvent(silent: true));
        break;

      case 'new-mechanic-address':
        // Real-time mechanic location update during accepted state.
        // Phase 4 (tracking screen) consumes mechanicLat/Lng to redraw route.
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          emit(state.copyWith(mechanicLat: lat, mechanicLng: lng));
        }
        break;

      case 'order-cancelled':
        emit(const OrderCanceled());
        break;

      case 'mechanic-cancelled-research':
        // Tanlangan mexanik orderni rad etdi - backend status'ni 'new' ga
        // qaytarib boshqa masterlarga qayta broadcast qildi. Mobile tarafda
        // OrderCanceled emit qilmaymiz (bu home'ga uchirgan bo'lardi); o'rniga
        // silent refresh - currentOrder.status pending'ga aylanadi va
        // OrderSingleScreen'dagi listener driverni offers ekraniga qaytaradi.
        add(GetCurrentOrderEvent(silent: true));
        break;

      default:
        // Ignore - InivitesBloc and others may handle this event.
        break;
    }
  }

  void _onCancelOrder(CancelOrderEvent event, Emitter<OrdersState> emit) async {
    final response = await orderRepository.cancelOrder(
      reasonId: event.reasonId,
      reasonText: event.reasonText,
    );
    if (response.errorText.isEmpty) {
      debugPrint('Order cancelled successfully');
      // OrderCanceled endi success + id=-1 holatini olib keladi - home
      // darrov recents ko'rinishiga o'tadi, ortiqcha ikkinchi emit kerak
      // emas.
      emit(const OrderCanceled());
      _syncWsRetention();
    } else {
      debugPrint('Error cancelling order: ${response.errorText}');
    }
  }

  void _onGetCurrentOrder(GetCurrentOrderEvent event, Emitter<OrdersState> emit) async {
    // Stale-while-revalidate: on silent refreshes (lifecycle resume, WS reconnect)
    // we already have order data on screen, so skip the `inProgress` flash and
    // just swap in fresh data when it arrives. Aktiv buyurtmasi yo'q user (id=-1)
    // ham success holatda - uni "data yo'q" deb hisoblamaymiz, aks holda skeleton
    // flash bo'ladi pull-to-refresh paytida.
    final hasData = state.currentOrderStatus.isSuccess;
    if (!(event.silent && hasData)) {
      emit(state.copyWith(currentOrderStatus: FormzSubmissionStatus.inProgress));
    }
    final response = await orderRepository.getCurrentOrder();
    if (response.errorText.isEmpty) {
      emit(state.copyWith(
        currentOrder: response.data,
        currentOrderStatus: FormzSubmissionStatus.success,
      ));
      _syncWsRetention();
    } else {
      emit(state.copyWith(currentOrderStatus: FormzSubmissionStatus.failure));
      debugPrint('Error fetching current order: ${response.errorText}');
    }
  }

  void _onChangeSubOrderStatus(ChangeSubOrderStatusEvent event, Emitter<OrdersState> emit) async {
    await orderRepository.changeSubOrderStatus(event.id, event.status);
    // Clear the pending suborder modal trigger.
    emit(state.clearPendingSubOrder());
    // Silent refresh - tracking UI ekranda turibdi, shimmer ko'rsatmaymiz.
    // Yangi suborder list va total_price jim almashtiriladi.
    add(GetCurrentOrderEvent(silent: true));
  }

  void _onDoneCurrentOrder(DoneCurrentOrderEvent event, Emitter<OrdersState> emit) async {
    emit(state.copyWith(doneOrderStatus: FormzSubmissionStatus.inProgress));
    final response = await orderRepository.doneCurrentOrder();
    if (response.errorText.isEmpty) {
      emit(state.copyWith(
        doneOrderStatus: FormzSubmissionStatus.success,
        code: response.data,
      ));
      event.onSuccess.call(response.data ?? 0);
    } else {
      emit(state.copyWith(doneOrderStatus: FormzSubmissionStatus.failure));
    }
  }

  void _onRateMaster(RateMasterEvent event, Emitter<OrdersState> emit) async {
    await orderRepository.rateMechanic(
      event.star, event.comment, event.mechanicId, tag: event.tag,
    );
  }

  void _onClearLifecycleEvent(ClearLifecycleEventEvent event, Emitter<OrdersState> emit) {
    emit(state.clearLifecycleEvent());
  }

  void _onClearPendingSubOrder(ClearPendingSubOrderEvent event, Emitter<OrdersState> emit) {
    emit(state.clearPendingSubOrder());
  }
}

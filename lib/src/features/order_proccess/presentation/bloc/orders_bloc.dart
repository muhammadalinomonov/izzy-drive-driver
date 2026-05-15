import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/core/services/connectivity_service.dart';
import 'package:taxi_app/src/core/services/websocket_service.dart';
import 'package:taxi_app/src/features/order_proccess/data/model/sub_order_model.dart';
import 'package:taxi_app/src/features/order_proccess/domain/entities/current_order_entity.dart';
import 'package:taxi_app/src/features/order_proccess/domain/order_repo.dart';

import '../../data/model/mechanic_arrived.dart';
import '../../data/model/order_accepted.dart';

part 'orders_event.dart';
part 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrderRepository orderRepository;
  final WebSocketService _ws = serviceLocator<WebSocketService>();
  StreamSubscription<Map<String, dynamic>>? _wsSub;
  StreamSubscription<bool>? _connectivitySub;
  bool _shouldBeConnected = false;

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
    on<ResetCurrentOrderEvent>((event, emit) => emit(const OrderCanceled()));

    _connectivitySub = serviceLocator<ConnectivityService>().onlineStream.listen((online) {
      if (online && _shouldBeConnected) {
        // The WS may still report _isConnected=true because onError/onDone
        // hadn't fired yet; force a clean reconnect through the bloc so
        // the subscription stays wired correctly.
        add(DisConnectFromWebSocketEvent());
        add(ConnectToWebSocketEvent());
      }
    });
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    _connectivitySub?.cancel();
    return super.close();
  }

  void _onConnectWebSocket(ConnectToWebSocketEvent event, Emitter<OrdersState> emit) {
    _ws.connect();
    _wsSub ??= _ws.stream.listen((data) => add(_WsMessageReceivedEvent(data)));
    _shouldBeConnected = true;
  }

  void _onDisconnectFromWebSocket(DisConnectFromWebSocketEvent event, Emitter<OrdersState> emit) {
    _wsSub?.cancel();
    _wsSub = null;
    _ws.disconnect();
    _shouldBeConnected = false;
  }

  void _onWsMessage(_WsMessageReceivedEvent event, Emitter<OrdersState> emit) {
    final data = event.data;
    // Backend uses both `event-status` (hyphen) and `event_status` (underscore)
    // inconsistently — read either to be defensive.
    final eventStatus = (data['event-status'] ?? data['event_status']) as String?;

    switch (eventStatus) {
      case 'order-accepted-at-mechanic':
        final orderAccepted = OrderAccepted.fromJson(data);
        emit(state.copyWith(orderAccepted: orderAccepted));
        add(GetCurrentOrderEvent());
        break;

      case 'mechanic-arrived':
        final mechanicArrived = MechanicArrived.fromJson(data);
        debugPrint('Mechanic arrived: $mechanicArrived');
        emit(state.copyWith(lifecycleEvent: OrderLifecycleEvent.arrived));
        add(GetCurrentOrderEvent());
        break;

      case 'mechanic-inprogress':
        emit(state.copyWith(lifecycleEvent: OrderLifecycleEvent.inProgress));
        add(GetCurrentOrderEvent());
        break;

      case 'mechanic-done':
        add(GetCurrentOrderEvent());
        break;

      case 'order-completed':
        emit(state.copyWith(lifecycleEvent: OrderLifecycleEvent.completed));
        add(GetCurrentOrderEvent());
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
        // Driver's response was accepted; refresh order to show updated suborders/total.
        add(GetCurrentOrderEvent());
        break;

      case 'update-order-price':
        // Pre-proposal price edit; refresh current order if any.
        add(GetCurrentOrderEvent());
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
      case 'selected-order-cancelled':
        emit(const OrderCanceled());
        break;

      default:
        // Ignore — InivitesBloc and others may handle this event.
        break;
    }
  }

  void _onCancelOrder(CancelOrderEvent event, Emitter<OrdersState> emit) async {
    final response = await orderRepository.cancelOrder();
    if (response.errorText.isEmpty) {
      debugPrint('Order cancelled successfully');
      // OrderCanceled endi success + id=-1 holatini olib keladi — home
      // darrov recents ko'rinishiga o'tadi, ortiqcha ikkinchi emit kerak
      // emas.
      emit(const OrderCanceled());
    } else {
      debugPrint('Error cancelling order: ${response.errorText}');
    }
  }

  void _onGetCurrentOrder(GetCurrentOrderEvent event, Emitter<OrdersState> emit) async {
    // Stale-while-revalidate: on silent refreshes (lifecycle resume, WS reconnect)
    // we already have order data on screen, so skip the `inProgress` flash and
    // just swap in fresh data when it arrives.
    final hasData = state.currentOrder.id != -1;
    if (!(event.silent && hasData)) {
      emit(state.copyWith(currentOrderStatus: FormzSubmissionStatus.inProgress));
    }
    final response = await orderRepository.getCurrentOrder();
    if (response.errorText.isEmpty) {
      emit(state.copyWith(
        currentOrder: response.data,
        currentOrderStatus: FormzSubmissionStatus.success,
      ));
    } else {
      emit(state.copyWith(currentOrderStatus: FormzSubmissionStatus.failure));
      debugPrint('Error fetching current order: ${response.errorText}');
    }
  }

  void _onChangeSubOrderStatus(ChangeSubOrderStatusEvent event, Emitter<OrdersState> emit) async {
    await orderRepository.changeSubOrderStatus(event.id, event.status);
    // Clear the pending suborder modal trigger.
    emit(state.clearPendingSubOrder());
    add(GetCurrentOrderEvent());
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
    await orderRepository.rateMechanic(event.star, event.comment, event.mechanicId);
  }

  void _onClearLifecycleEvent(ClearLifecycleEventEvent event, Emitter<OrdersState> emit) {
    emit(state.clearLifecycleEvent());
  }

  void _onClearPendingSubOrder(ClearPendingSubOrderEvent event, Emitter<OrdersState> emit) {
    emit(state.clearPendingSubOrder());
  }
}

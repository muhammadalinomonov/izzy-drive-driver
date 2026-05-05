import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/features/order_proccess/data/model/sub_order_model.dart';
import 'package:taxi_app/src/features/order_proccess/domain/entities/current_order_entity.dart';
import 'package:taxi_app/src/features/order_proccess/domain/order_repo.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../data/model/mechanic_arrived.dart';
import '../../data/model/order_accepted.dart';

part 'orders_event.dart';
part 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrderRepository orderRepository;

  bool _isConnected = false;
  WebSocketChannel? _channel;

  OrdersBloc({required this.orderRepository}) : super(const OrdersState()) {
    on<ConnectToWebSocketEvent>(_onConnectWebSocket);
    on<DisConnectFromWebSocketEvent>(_onDisconnectFromWebSocket);
    on<CancelOrderEvent>(_onCancelOrder);
    on<GetCurrentOrderEvent>(_onGetCurrentOrder);
    on<ChangeSubOrderStatusEvent>(_onChangeSubOrderStatus);
    on<DoneCurrentOrderEvent>(_onDoneCurrentOrder);
    on<RateMasterEvent>(_onRateMaster);
    on<ClearLifecycleEventEvent>(_onClearLifecycleEvent);
    on<ClearPendingSubOrderEvent>(_onClearPendingSubOrder);
  }

  @override
  Future<void> close() {
    _channel?.sink.close();
    _isConnected = false;
    return super.close();
  }

  void _onConnectWebSocket(ConnectToWebSocketEvent event, Emitter<OrdersState> emit) async {
    try {
      _channel?.sink.close();
      if (_isConnected) {
        return;
      }
      final wsId = StorageRepository.getInt('ws_id');
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://ws.quadrix.ai/ws?user_id=$wsId&tab_id=1&browser_id=browser_1'),
      );
      _isConnected = true;
      print('WebSocket Connected');
      await _listenToWebSocket(emit);
    } catch (e) {
      print(e);
    }
  }

  void _onDisconnectFromWebSocket(DisConnectFromWebSocketEvent event, Emitter<OrdersState> emit) {
    _channel?.sink.close();
    _isConnected = false;
  }

  Future<void> _listenToWebSocket(Emitter<OrdersState> emit) async {
    if (_channel == null) {
      return;
    }
    try {
      await for (final message in _channel!.stream) {
        _handleMessage(message, emit);
      }
    } catch (e) {
      print("WebSocket Error: $e");
      _isConnected = false;
    } finally {
      print("WebSocket Disconnected");
      _isConnected = false;
    }
  }

  void _handleMessage(String message, Emitter<OrdersState> emit) {
    final json = jsonDecode(message) as Map<String, dynamic>;
    print("WebSocket Message: $message");

    final eventType = json['event'] as String?;
    if (eventType != 'direct') return;

    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) return;

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
        // Note: parser reads top-level `json`, not `data` — keep existing behavior.
        final mechanicArrived = MechanicArrived.fromJson(json);
        print("Mechanic arrived: ${mechanicArrived.toString()}");
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
          print('Failed to parse new-suborder: $e');
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
        _channel?.sink.close();
        _isConnected = false;
        emit(const OrderCanceled());
        break;

      default:
        print('Unhandled WS event-status: $eventStatus');
    }
  }

  void _onCancelOrder(CancelOrderEvent event, Emitter<OrdersState> emit) async {
    final response = await orderRepository.cancelOrder();
    if (response.errorText.isEmpty) {
      print('Order cancelled successfully');
      _channel?.sink.close();
      _isConnected = false;
      emit(const OrderCanceled());
      // Reset to a "no current order" state so the home card disappears
      // immediately instead of showing a stale/error UI.
      emit(const OrdersState(
        currentOrderStatus: FormzSubmissionStatus.success,
        currentOrder: CurrentOrderEntity(),
      ));
    } else {
      print('Error cancelling order: ${response.errorText}');
    }
  }

  void _onGetCurrentOrder(GetCurrentOrderEvent event, Emitter<OrdersState> emit) async {
    emit(state.copyWith(currentOrderStatus: FormzSubmissionStatus.inProgress));
    final response = await orderRepository.getCurrentOrder();
    if (response.errorText.isEmpty) {
      print('Current order fetched successfully');
      emit(state.copyWith(
        currentOrder: response.data,
        currentOrderStatus: FormzSubmissionStatus.success,
      ));
    } else {
      emit(state.copyWith(currentOrderStatus: FormzSubmissionStatus.failure));
      print('Error fetching current order: ${response.errorText}');
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
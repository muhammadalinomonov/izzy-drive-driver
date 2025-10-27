// Updated File: orders_bloc.dart
import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/features/order_proccess/data/model/cancel_order_response.dart';
import 'package:taxi_app/src/features/order_proccess/domain/entities/current_order_entity.dart';
import 'package:taxi_app/src/features/order_proccess/domain/order_repo.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../data/model/mechanic_arrived.dart';
import '../../data/model/order_accepted.dart'; // New import
import '../../data/order_proccess_source.dart';

part 'orders_event.dart';
part 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  bool _isConnected = false;

  WebSocketChannel? _channel;

  OrdersBloc() : super(OrdersState()) {
    on<ConnectToWebSocketEvent>(_onConnectWebSocket);
    on<DisConnectFromWebSocketEvent>(_onDisconnectFromWebSocket);
    on<CancelOrderEvent>(_onCancelOrder);
    on<GetCurrentOrderEvent>(_onGetCurrentOrder);
    on<ChangeSubOrderStatusEvent>(_onChangeSubOrderStatus);
    on<DoneCurrentOrderEvent>(_onDoneCurrentOrder);
    on<RateMasterEvent>(_onRateMaster);
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
    var orderID = StorageRepository.getString("reportID");
    print("WebSocket Message: $message");

    final event = json['event'] as String?;
    if (event == 'direct') {
      final data = json['data'] as Map<String, dynamic>?;
      if (data != null) {
        add(GetCurrentOrderEvent());
        final eventStatus = data['event-status'] as String?;
        if (eventStatus == 'mechanic-arrived') {
          var mechanicArrived = MechanicArrived.fromJson(json);
          print("Mechanic arrived: ${mechanicArrived.toString()}");
          // Emit state if needed for mechanic arrived
        } else if (eventStatus == 'order-accepted-at-mechanic') {
          final orderAccepted = OrderAccepted.fromJson(data);
          print("Order accepted: ${orderAccepted.toString()}");
          emit(state.copyWith(orderAccepted: orderAccepted));
        }
      }
    }
  }

  void _onCancelOrder(CancelOrderEvent event, Emitter<OrdersState> emit) async {
    var orderID = StorageRepository.getString("reportID");
    var repo = OrderRepositoryImpl(orderProccessSource: OrderProccessSource());
    var networkResponse = await repo.cancelOrder(orderID);
    if (networkResponse.errorText.isEmpty) {
      print('Order cancelled successfully');
      var cancelOrderResponse = CancelOrderResponse.fromJson(networkResponse.data);
      _channel?.sink.close();
      _isConnected = false;
      emit(OrderCanceled(cancelOrderResponse: cancelOrderResponse));
    } else {
      print('Error cancelling order: ${networkResponse.errorText}');
    }
  }

  void _onGetCurrentOrder(GetCurrentOrderEvent event, Emitter<OrdersState> emit) async {
    emit(state.copyWith(currentOrderStatus: FormzSubmissionStatus.inProgress));
    var repo = OrderRepositoryImpl(orderProccessSource: OrderProccessSource());
    var networkResponse = await repo.getCurrentOrder();
    if (networkResponse.errorText.isEmpty) {
      print('Current order fetched successfully');
      var currentOrder = networkResponse.data;
      emit(state.copyWith(currentOrder: currentOrder, currentOrderStatus: FormzSubmissionStatus.success));
    } else {
      emit(state.copyWith(currentOrderStatus: FormzSubmissionStatus.failure));
      print('Error fetching current order: ${networkResponse.errorText}');
    }
  }

  void _onChangeSubOrderStatus(ChangeSubOrderStatusEvent event, Emitter<OrdersState> emit) async {
    var repo = OrderRepositoryImpl(orderProccessSource: OrderProccessSource());
    await repo.changeSubOrderStatus(event.id, event.status);

    add(GetCurrentOrderEvent());
  }

  void _onDoneCurrentOrder(DoneCurrentOrderEvent event, Emitter<OrdersState> emit) async {
    var repo = OrderRepositoryImpl(orderProccessSource: OrderProccessSource());
    emit(state.copyWith(doneOrderStatus: FormzSubmissionStatus.inProgress));
    var networkResponse = await repo.doneCurrentOrder();
    if (networkResponse.errorText.isEmpty) {
      emit(state.copyWith(doneOrderStatus: FormzSubmissionStatus.success, code: networkResponse.data));

      event.onSuccess.call(networkResponse.data ?? 0);
    } else {
      emit(state.copyWith(doneOrderStatus: FormzSubmissionStatus.failure));
    }
  }

  void _onRateMaster(RateMasterEvent event, Emitter<OrdersState> emit) async {
    var repo = OrderRepositoryImpl(orderProccessSource: OrderProccessSource());
    await repo.rateMechanic(event.star, event.comment, event.mechanicId);
  }
}

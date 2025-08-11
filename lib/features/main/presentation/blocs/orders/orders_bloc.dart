import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:mechanic/core/storage/storage_repository.dart';
import 'package:mechanic/core/storage/store_keys.dart';
import 'package:mechanic/core/utils/service_locator.dart';
import 'package:mechanic/features/main/domain/entities/order_detail_entity.dart';
import 'package:mechanic/features/main/domain/entities/order_entity.dart';
import 'package:mechanic/features/main/domain/usecases/get_order_detail_usecase.dart';
import 'package:mechanic/features/main/domain/usecases/get_orders_usecase.dart';
import 'package:mechanic/features/main/domain/usecases/send_application_usecase.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'orders_event.dart';
part 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final GetOrdersUseCase _getOrdersUseCase = GetOrdersUseCase(repository: serviceLocator.call());
  final GetOrderDetailUseCase _getOrderDetailUseCase = GetOrderDetailUseCase(repository: serviceLocator.call());
  final SendApplicationUseCase _sendApplicationUseCase = SendApplicationUseCase(repository: serviceLocator.call());
  bool _isConnected = false;

  WebSocketChannel? _channel;

  OrdersBloc() : super(OrdersState()) {
    on<GetOrdersEvent>(_onGetOrdersEvent);
    on<GetMoreOrdersEvent>(_onGetMoreOrdersEvent);
    on<GetOrderDetailEvent>(_onGetOrderDetailEvent);
    on<SendApplicationEvent>(_onSendApplicationEvent);
    on<ConnectToWebSocketEvent>(_onConnectWebSocket);
    on<DisConnectFromWebSocketEvent>(_onDisconnectFromWebSocket);
  }

  void _onGetOrdersEvent(GetOrdersEvent event, Emitter<OrdersState> emit) async {
    emit(state.copyWith(ordersStatus: FormzSubmissionStatus.inProgress));

    final result = await _getOrdersUseCase(null);

    if (result.isRight) {
      emit(
        state.copyWith(
          ordersStatus: FormzSubmissionStatus.success,
          orders: result.right.data,
          nextOrders: result.right.next,
          hasMoreOrders: result.right.next != null,
        ),
      );
    } else {
      emit(state.copyWith(ordersStatus: FormzSubmissionStatus.failure));
    }
  }

  void _onGetMoreOrdersEvent(GetMoreOrdersEvent event, Emitter<OrdersState> emit) async {
    final result = await _getOrdersUseCase(state.nextOrders);

    if (result.isRight) {
      emit(
        state.copyWith(
          ordersStatus: FormzSubmissionStatus.success,
          orders: [...state.orders, ...result.right.data ?? []],
          nextOrders: result.right.next,
          hasMoreOrders: result.right.next != null,
        ),
      );
    }
  }

  void _onGetOrderDetailEvent(GetOrderDetailEvent event, Emitter<OrdersState> emit) async {
    emit(state.copyWith(orderDetailStatus: FormzSubmissionStatus.inProgress));
    final result = await _getOrderDetailUseCase(event.orderId);
    if (result.isRight && result.right.data != null) {
      emit(
        state.copyWith(
          orderDetailStatus: FormzSubmissionStatus.success,
          orderDetail: result.right.data,
        ),
      );
    } else {
      emit(state.copyWith(orderDetailStatus: FormzSubmissionStatus.failure));
    }
  }

  void _onSendApplicationEvent(SendApplicationEvent event, Emitter<OrdersState> emit) async {
    emit(state.copyWith(sendApplicationStatus: FormzSubmissionStatus.inProgress));
    final result = await _sendApplicationUseCase(
      (orderId: event.orderId, comment: event.comment, price: event.proposedPrice),
    );
    if (result.isRight) {
      emit(state.copyWith(sendApplicationStatus: FormzSubmissionStatus.success));
    } else {
      emit(state.copyWith(sendApplicationStatus: FormzSubmissionStatus.failure));
    }
  }

  void _onConnectWebSocket(ConnectToWebSocketEvent event, Emitter<OrdersState> emit) async {
    try {
      _channel?.sink.close();
      if (_isConnected) {
        return;
      }
      final wsId = StorageRepository.getInt(StoreKeys.wsId);
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://ws.quadrix.ai/ws?user_id=$wsId&tab_id=1&browser_id=browser_1'),
      );
      _isConnected = true;
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
    final json  = jsonDecode(message);
    final type = json['type'] as String?;
  }
}

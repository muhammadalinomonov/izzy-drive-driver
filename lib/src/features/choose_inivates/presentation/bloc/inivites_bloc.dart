import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/core/services/websocket_service.dart';

import '../../data/model/active_order.dart';
import '../../domain/active_order_repository.dart';

part 'inivites_event.dart';

part 'inivites_state.dart';

class InivitesBloc extends Bloc<InivitesEvent, InivitesState> {
  final ActiveOrderRepository activeOrderRepository;
  final WebSocketService _ws = serviceLocator<WebSocketService>();
  StreamSubscription<Map<String, dynamic>>? _wsSub;
  // True while this bloc currently holds a retain on the WS. Prevents
  // double-retain when FetchActiveOrderEvent is dispatched repeatedly
  // (polling, ws-driven refresh).
  bool _wsRetained = false;

  InivitesBloc({required this.activeOrderRepository}) : super(InivitesInitial()) {
    on<FetchActiveOrderEvent>(_onFetchActiveOrder);
    on<ConnectToWebSocketEvent>(_onConnectWebSocket);
    on<DisconnectFromWebSocketEvent>(_onDisconnectFromWebSocket);
    on<NewProposalReceivedEvent>(_onNewProposalReceived);
    on<UpdateOrderPriceEvent>(_onUpdateOrderPrice);
    on<CancelActiveOrderEvent>(_onCancelActiveOrder);
    on<_WsMessageReceivedEvent>(_onWsMessage);
  }

  Future<void> _onCancelActiveOrder(CancelActiveOrderEvent event, Emitter<InivitesState> emit) async {
    final previous = state;
    emit(InivitesLoading());
    final response = await activeOrderRepository.cancelOrder();
    if (response.errorText.isEmpty) {
      add(DisconnectFromWebSocketEvent());
      emit(InivitesCancelled());
    } else {
      // Restore the previous state so the offers list and proposal
      // stream stay intact - only surface the error.
      if (previous is InivitesLoaded) {
        emit(previous);
      }
      emit(InivitesError(response.errorText));
    }
  }

  // Dastlabki takliflarni yuklash
  void _onFetchActiveOrder(FetchActiveOrderEvent event, Emitter<InivitesState> emit) async {
    emit(InivitesLoading());
    try {
      final response = await activeOrderRepository.fetchActiveOrder();
      if (response.data != null) {
        final orderResponse = response.data as OrderResponse;
        emit(InivitesLoaded(orderResponse));

        // Subscribe to the shared WebSocket once data is ready.
        add(ConnectToWebSocketEvent());
      } else {
        emit(InivitesError(response.errorText ?? 'Unknown error'));
      }
    } catch (e) {
      emit(InivitesError(e.toString()));
    }
  }

  // Subscribe to the shared WS service. The actual socket is owned by
  // [WebSocketService] — bu yerda faqat listener qo'shamiz va ref-count
  // retain'ni boshqaramiz. Polling refresh paytida event qayta-qayta
  // dispatch bo'lishi mumkin, shuning uchun [_wsRetained] flag dublyajni
  // oldini oladi.
  void _onConnectWebSocket(ConnectToWebSocketEvent event, Emitter<InivitesState> emit) {
    if (_wsRetained) return;
    _ws.connect();
    _wsSub ??= _ws.stream.listen((data) => add(_WsMessageReceivedEvent(data)));
    _wsRetained = true;
  }

  void _onDisconnectFromWebSocket(DisconnectFromWebSocketEvent event, Emitter<InivitesState> emit) {
    if (!_wsRetained) return;
    _wsSub?.cancel();
    _wsSub = null;
    // Ref-counted release: agar OrdersBloc ham retain qilgan bo'lsa, WS
    // ochiq qoladi. Aks holda bu oxirgi retain edi va WS yopiladi.
    _ws.disconnect();
    _wsRetained = false;
  }

  void _onWsMessage(_WsMessageReceivedEvent event, Emitter<InivitesState> emit) {
    final data = event.data;
    // Backend may use either `event` or `event-status`/`event_status` for the inner key.
    final eventType = (data['event'] ?? data['event-status'] ?? data['event_status']) as String?;
    if (eventType == 'new-proposal') {
      debugPrint('New proposal received: ${data['mechanic_name']}');
      final newProposal = _parseNewProposal(data);
      add(NewProposalReceivedEvent(newProposal));
    } else if (eventType == 'update-order-price') {
      debugPrint('Order price updated via WS - refreshing active order');
      add(FetchActiveOrderEvent());
    }
  }

  // Yangi taklifni parse qilish
  OrderData _parseNewProposal(Map<String, dynamic> data) {
    return OrderData(
      id: data['id'] ?? 0,
      mechanicId: data['mechanic_id'] ?? 0,
      mechanicName: data['mechanic_name'] ?? 'Unknown',
      proposedPrice: (data['proposed_price'] ?? 0).toDouble(),
      shopAddress: data['shop_address'] ?? 'Unknown address',
      distance: (data['distance'] ?? 0.0).toDouble(),
      balance: data['balance'] ?? 'equal',
      changePercent: (data['change_percent'] ?? 0.0).toDouble(),
      avatar: data['avatar'],
      createdAt: data['created_at'] ?? DateTime.now().toIso8601String(),
      mechanicCurrentAddress: data['mechanic_current_address'] ?? '',
      workTimeEstimateMin: (data['work_time_estimate_min'] as num?)?.toInt(),
    );
  }

  // Yangi taklif qo'shish
  void _onNewProposalReceived(NewProposalReceivedEvent event, Emitter<InivitesState> emit) {
    final currentState = state;
    if (currentState is InivitesLoaded) {
      // Mavjud takliflarga yangi taklifni qo'shish
      final updatedOffers = List<OrderData>.from(currentState.orderResponse.data);

      // Agar bu taklif allaqachon mavjud bo'lmasa qo'shish
      final existingIndex = updatedOffers.indexWhere((offer) => offer.id == event.newProposal.id);
      if (existingIndex != -1) {
        // Mavjud taklifni yangilash
        updatedOffers[existingIndex] = event.newProposal;
      } else {
        // Yangi taklifni boshiga qo'shish (eng yangisi yuqorida bo'lishi uchun)
        updatedOffers.insert(0, event.newProposal);
      }

      // Yangilangan ma'lumotlar bilan yangi OrderResponse yaratish
      final updatedOrderResponse = OrderResponse(
        order: currentState.orderResponse.order,
        data: updatedOffers,
        status: currentState.orderResponse.status,
        message: currentState.orderResponse.message,
        total: currentState.orderResponse.total,
        totalPages: currentState.orderResponse.totalPages,
        currentPage: currentState.orderResponse.currentPage,
      );

      emit(InivitesLoaded(updatedOrderResponse));
    }
  }

  Future<void> _onUpdateOrderPrice(UpdateOrderPriceEvent event, Emitter<InivitesState> emit) async {
    try {
      if (state is InivitesLoaded) {
        final order = (state as InivitesLoaded).orderResponse;

        emit(InivitesLoading());
        final response = await activeOrderRepository.updateOrderPrice(event.price);
        if (response.data != null) {
          final newOrder = order.copyWith(
            order: order.order.copyWith(price: event.price, totalPrice: event.price),
          );
          emit(InivitesLoaded(newOrder));
          add(ConnectToWebSocketEvent());
        } else {
          emit(InivitesError(response.errorText ?? 'Unknown error'));
        }
      }
    } catch (e) {
      emit(InivitesError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    if (_wsRetained) {
      _ws.disconnect();
      _wsRetained = false;
    }
    return super.close();
  }
}

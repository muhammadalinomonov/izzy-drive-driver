import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:taxi_app/src/core/constants/feature_flags.dart';
import 'package:taxi_app/src/core/network/token_service.dart';

import '../../data/model/active_order.dart';
import '../../domain/active_order_repository.dart';

part 'inivites_event.dart';

part 'inivites_state.dart';

class InivitesBloc extends Bloc<InivitesEvent, InivitesState> {
  final ActiveOrderRepository activeOrderRepository;
  WebSocketChannel? _channel;
  bool _isConnected = false;

  InivitesBloc({required this.activeOrderRepository}) : super(InivitesInitial()) {
    on<FetchActiveOrderEvent>(_onFetchActiveOrder);
    on<ConnectToWebSocketEvent>(_onConnectWebSocket);
    on<DisconnectFromWebSocketEvent>(_onDisconnectFromWebSocket);
    on<NewProposalReceivedEvent>(_onNewProposalReceived);
    on<UpdateOrderPriceEvent>(_onUpdateOrderPrice);
  }

  // Dastlabki takliflarni yuklash
  void _onFetchActiveOrder(FetchActiveOrderEvent event, Emitter<InivitesState> emit) async {
    emit(InivitesLoading());
    try {
      final response = await activeOrderRepository.fetchActiveOrder();
      if (response.data != null) {
        final orderResponse = response.data as OrderResponse;
        emit(InivitesLoaded(orderResponse));

        // Ma'lumotlar yuklangandan so'ng WebSocket'ga ulaning
        if (!_isConnected) {
          add(ConnectToWebSocketEvent());
        }
      } else {
        emit(InivitesError(response.errorText ?? 'Unknown error'));
      }
    } catch (e) {
      emit(InivitesError(e.toString()));
    }
  }

  // WebSocket'ga ulanish
  void _onConnectWebSocket(ConnectToWebSocketEvent event, Emitter<InivitesState> emit) async {
    if (!FeatureFlags.webSocketEnabled) {
      print('WebSocket disabled by feature flag — skipping invites connect');
      return;
    }
    try {
      // Agar allaqachon ulangan bo'lsa, qaytaring
      if (_isConnected && _channel != null) {
        print('WebSocket already connected');
        return;
      }

      // Avvalgi ulanishni yoping
      await _channel?.sink.close();
      _isConnected = false;

      final wsId = StorageRepository.getInt('ws_id');
      if (wsId == null) {
        print('ws_id not found');
        return;
      }

      _channel = WebSocketChannel.connect(
        Uri.parse('wss://ws.quadrix.ai/ws?user_id=usta_client_$wsId&tab_id=1&browser_id=browser_1'),
      );
      _isConnected = true;
      print('WebSocket Connected for Invites with usta_client=: $wsId');

      // Alohida funksiya sifatida chaqiring
      _startListening(emit);
    } catch (e) {
      print('WebSocket connection error: $e');
      _isConnected = false;
    }
  }

  // WebSocket'dan uzilish
  void _onDisconnectFromWebSocket(DisconnectFromWebSocketEvent event, Emitter<InivitesState> emit) async {
    try {
      await _channel?.sink.close();
      _channel = null;
      _isConnected = false;
      print('WebSocket Disconnected for Invites');
    } catch (e) {
      print('Error disconnecting WebSocket: $e');
    }
  }

  // WebSocket xabarlarini tinglashni boshlash
  void _startListening(Emitter<InivitesState> emit) {
    if (_channel == null) return;

    _channel!.stream.listen(
      (message) {
        _handleWebSocketMessage(message, emit);
      },
      onError: (error) {
        print("WebSocket Error: $error");
        _isConnected = false;
      },
      onDone: () {
        print("WebSocket Connection Closed");
        _isConnected = false;
      },
    );
  }

  // WebSocket xabarlarini qayta ishlash
  void _handleWebSocketMessage(String message, Emitter<InivitesState> emit) {
    try {
      final json = jsonDecode(message) as Map<String, dynamic>;
      print("WebSocket Message: $message");

      final event = json['event'] as String?;
      if (event == 'direct') {
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          // Backend uses both `event` and `event-status`/`event_status` for inner key.
          final eventType = (data['event'] ?? data['event-status'] ?? data['event_status']) as String?;
          if (eventType == 'new-proposal') {
            print('New proposal received: ${data['mechanic_name']}');
            final newProposal = _parseNewProposal(data);
            add(NewProposalReceivedEvent(newProposal));
          } else if (eventType == 'update-order-price') {
            print('Order price updated via WS — refreshing active order');
            add(FetchActiveOrderEvent());
          }
        }
      }
    } catch (e) {
      print("Error parsing WebSocket message: $e");
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
    );
  }

  // Yangi taklif qo'shish
  void _onNewProposalReceived(NewProposalReceivedEvent event, Emitter<InivitesState> emit) {
    final currentState = state;
    if (currentState is InivitesLoaded) {
      print('Adding new proposal to list: ${event.newProposal.mechanicName}');

      // Mavjud takliflarga yangi taklifni qo'shish
      final updatedOffers = List<OrderData>.from(currentState.orderResponse.data);

      // Agar bu taklif allaqachon mavjud bo'lmasa qo'shish
      final existingIndex = updatedOffers.indexWhere((offer) => offer.id == event.newProposal.id);
      if (existingIndex != -1) {
        // Mavjud taklifni yangilash
        updatedOffers[existingIndex] = event.newProposal;
        print('Updated existing proposal');
      } else {
        // Yangi taklifni boshiga qo'shish (eng yangisi yuqorida bo'lishi uchun)
        updatedOffers.insert(0, event.newProposal);
        print('Added new proposal to list. Total offers: ${updatedOffers.length}');
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
    } else {
      print('Current state is not InvitesLoaded, cannot add proposal');
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

          // Ma'lumotlar yuklangandan so'ng WebSocket'ga ulaning
          if (!_isConnected) {
            add(ConnectToWebSocketEvent());
          }
        } else {
          emit(InivitesError(response.errorText ?? 'Unknown error'));
        }
      }
    } catch (e) {
      emit(InivitesError(e.toString()));
    }
  }

  @override
  Future<void> close() async {
    await _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    return super.close();
  }
}

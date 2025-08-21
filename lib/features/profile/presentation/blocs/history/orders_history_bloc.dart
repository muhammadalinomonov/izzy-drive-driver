import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:mechanic/core/utils/service_locator.dart';
import 'package:mechanic/features/main/domain/entities/current_order_entity.dart';
import 'package:mechanic/features/main/domain/entities/order_with_date_entity.dart';
import 'package:mechanic/features/main/domain/usecases/get_order_history_detail_usecase.dart';
import 'package:mechanic/features/main/domain/usecases/get_orders_history_usecase.dart';
import 'package:meta/meta.dart';

part 'orders_history_event.dart';
part 'orders_history_state.dart';

class OrdersHistoryBloc extends Bloc<OrdersHistoryEvent, OrdersHistoryState> {
  final GetOrdersHistoryUseCase _getOrdersHistoryUseCase = GetOrdersHistoryUseCase(repository: serviceLocator.call());
  final GetOrderHistoryDetailUseCase _getOrderHistoryDetailUseCase =
      GetOrderHistoryDetailUseCase(repository: serviceLocator.call());

  OrdersHistoryBloc() : super(OrdersHistoryState()) {
    on<GetOrdersHistoryEvent>(_onGetOrdersHistoryEvent);
    on<GetMoreOrdersHistoryEvent>(_onGetMoreOrdersHistoryEvent);
    on<GetOrderHistoryDetailEvent>(_onGetOrderHistoryDetailEvent);
  }

  Future<void> _onGetOrdersHistoryEvent(GetOrdersHistoryEvent event, Emitter<OrdersHistoryState> emit) async {
    emit(state.copyWith(ordersHistoryStatus: FormzSubmissionStatus.inProgress));

    final result = await _getOrdersHistoryUseCase(null);

    if (result.isRight) {
      emit(state.copyWith(
        ordersHistoryStatus: FormzSubmissionStatus.success,
        ordersHistory: result.right.data,
        nextOrdersHistory: result.right.next,
        hasMoreOrdersHistory: result.right.next != null,
        totalPrice: double.tryParse(result.right.totalSum)??0,
      ));
    } else {
      emit(state.copyWith(ordersHistoryStatus: FormzSubmissionStatus.failure));
    }
  }

  Future<void> _onGetMoreOrdersHistoryEvent(GetMoreOrdersHistoryEvent event, Emitter<OrdersHistoryState> emit) async {
    final result = await _getOrdersHistoryUseCase(state.nextOrdersHistory);
    if (result.isRight) {
      emit(state.copyWith(
        ordersHistory: [...state.ordersHistory, ...result.right.data ?? []],
        nextOrdersHistory: result.right.next,
        hasMoreOrdersHistory: result.right.next != null,
      ));
    }
  }

  Future<void> _onGetOrderHistoryDetailEvent(GetOrderHistoryDetailEvent event, Emitter<OrdersHistoryState> emit) async {
    emit(state.copyWith(orderHistoryDetailStatus: FormzSubmissionStatus.inProgress));

    final result = await _getOrderHistoryDetailUseCase(event.orderId);

    if (result.isRight) {
      emit(state.copyWith(
        orderHistoryDetailStatus: FormzSubmissionStatus.success,
        orderHistoryDetail: result.right.data,
      ));
    } else {
      emit(state.copyWith(orderHistoryDetailStatus: FormzSubmissionStatus.failure));
    }
  }
}

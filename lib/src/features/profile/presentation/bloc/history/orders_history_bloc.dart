import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:meta/meta.dart';
import 'package:taxi_app/src/features/order_proccess/domain/entities/current_order_entity.dart';
import 'package:taxi_app/src/features/profile/data/repository/profile_repository_impl.dart';
import 'package:taxi_app/src/features/profile/data/source/profile_data_source.dart';
import 'package:taxi_app/src/features/profile/domain/entities/order_history_entity.dart';
import 'package:taxi_app/src/features/profile/domain/repository/profile_repository.dart';

part 'orders_history_event.dart';
part 'orders_history_state.dart';

class OrdersHistoryBloc extends Bloc<OrdersHistoryEvent, OrdersHistoryState> {
  final ProfileRepository _profileRepository = ProfileRepositoryImpl(ProfileDataSource());

    OrdersHistoryBloc() : super(OrdersHistoryState()) {
    on<GetOrdersHistoryEvent>(_onGetOrdersHistoryEvent);
    on<GetMoreOrdersHistoryEvent>(_onGetMoreOrdersHistoryEvent);
    on<GetOrderHistoryDetailEvent>(_onGetOrderHistoryDetailEvent);
  }

  Future<void> _onGetOrdersHistoryEvent(GetOrdersHistoryEvent event, Emitter<OrdersHistoryState> emit) async {
    // Stale-while-revalidate: keep the existing list visible on silent refresh
    // (pull-to-refresh has its own spinner UI) instead of swapping in the
    // central CircularProgressIndicator over the whole screen. Bo'sh history
    // ham success holat - "data yo'q" deb qaramaymiz, aks holda skeleton flash.
    final hasData = state.ordersHistoryStatus.isSuccess;
    if (!(event.silent && hasData)) {
      emit(state.copyWith(ordersHistoryStatus: FormzSubmissionStatus.inProgress));
    }

    final result = await _profileRepository.getOrdersHistory();

    if (result.isRight) {
      emit(
        state.copyWith(
          ordersHistoryStatus: FormzSubmissionStatus.success,
          ordersHistory: result.right.data,
          nextOrdersHistory: result.right.next,
          hasMoreOrdersHistory: result.right.next != null,
          totalPrice: result.right.totalSum,
        ),
      );
    } else {
      emit(state.copyWith(ordersHistoryStatus: FormzSubmissionStatus.failure));
    }
  }

  Future<void> _onGetMoreOrdersHistoryEvent(GetMoreOrdersHistoryEvent event, Emitter<OrdersHistoryState> emit) async {
    final result = await _profileRepository.getOrdersHistory(next: state.nextOrdersHistory);
    if (result.isRight) {
      emit(
        state.copyWith(
          ordersHistory: [...state.ordersHistory, ...result.right.data ?? []],
          nextOrdersHistory: result.right.next,
          hasMoreOrdersHistory: result.right.next != null,
        ),
      );
    }
  }

  Future<void> _onGetOrderHistoryDetailEvent(GetOrderHistoryDetailEvent event, Emitter<OrdersHistoryState> emit) async {
    emit(state.copyWith(orderHistoryDetailStatus: FormzSubmissionStatus.inProgress));

    final result = await _profileRepository.getOrderHistoryDetail(id: event.orderId);

    if (result.isRight) {
      emit(state.copyWith(orderHistoryDetailStatus: FormzSubmissionStatus.success, orderHistoryDetail: result.right));
    } else {
      emit(state.copyWith(orderHistoryDetailStatus: FormzSubmissionStatus.failure));
    }
  }
}

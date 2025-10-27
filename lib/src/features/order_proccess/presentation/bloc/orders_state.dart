// Updated File: orders_state.dart
part of 'orders_bloc.dart';

@immutable
class OrdersState extends Equatable {
  final OrderAccepted? orderAccepted;
  final FormzSubmissionStatus currentOrderStatus;
  final CurrentOrderEntity currentOrder;
  final FormzSubmissionStatus doneOrderStatus;
  final int code;

  const OrdersState({
    this.orderAccepted,
    this.currentOrderStatus = FormzSubmissionStatus.initial,
    this.currentOrder = const CurrentOrderEntity(),
    this.doneOrderStatus = FormzSubmissionStatus.initial,
    this.code = -1,
  });

  OrdersState copyWith({
    OrderAccepted? orderAccepted,
    FormzSubmissionStatus? currentOrderStatus,
    CurrentOrderEntity? currentOrder,
    FormzSubmissionStatus? doneOrderStatus,
    int? code,

  }) {
    return OrdersState(
      orderAccepted: orderAccepted ?? this.orderAccepted,
      currentOrderStatus: currentOrderStatus ?? this.currentOrderStatus,
      currentOrder: currentOrder ?? this.currentOrder,
      doneOrderStatus: doneOrderStatus ?? this.doneOrderStatus,
      code: code ?? this.code,
    );
  }

  @override
  List<Object?> get props => [
    orderAccepted,
    currentOrderStatus,
    currentOrder,
    doneOrderStatus,
    code,
  ];
}
class OrderCanceled extends OrdersState {
  final CancelOrderResponse cancelOrderResponse;
  const OrderCanceled({
    required this.cancelOrderResponse,
  });

}
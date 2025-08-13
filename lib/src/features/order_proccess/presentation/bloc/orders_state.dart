// Updated File: orders_state.dart
part of 'orders_bloc.dart';

@immutable
class OrdersState extends Equatable {
  final OrderAccepted? orderAccepted;

  const OrdersState({
    this.orderAccepted,
  });

  OrdersState copyWith({
    OrderAccepted? orderAccepted,
  }) {
    return OrdersState(
      orderAccepted: orderAccepted ?? this.orderAccepted,
    );
  }

  @override
  List<Object?> get props => [
    orderAccepted,
  ];
}
class OrderCanceled extends OrdersState {
  final CancelOrderResponse cancelOrderResponse;
  const OrderCanceled({
    required this.cancelOrderResponse,
  });

}
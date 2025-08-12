part of 'orders_bloc.dart';

@immutable
class OrdersState extends Equatable {
  final List<OrderEntity> orders;
  final FormzSubmissionStatus ordersStatus;
  final String nextOrders;
  final bool hasMoreOrders;
  final FormzSubmissionStatus orderDetailStatus;
  final OrderDetailEntity orderDetail;
  final FormzSubmissionStatus sendApplicationStatus;
  final FormzSubmissionStatus getCurrentOrderStatus;
  final CurrentOrderEntity currentOrder;

  const OrdersState({
    this.orders = const [],
    this.ordersStatus = FormzSubmissionStatus.initial,
    this.nextOrders = '',
    this.hasMoreOrders = true,
    this.orderDetailStatus = FormzSubmissionStatus.initial,
    this.orderDetail = const OrderDetailEntity(),
    this.sendApplicationStatus = FormzSubmissionStatus.initial,
    this.getCurrentOrderStatus = FormzSubmissionStatus.initial,
    this.currentOrder = const CurrentOrderEntity(),
  });

  OrdersState copyWith({
    List<OrderEntity>? orders,
    FormzSubmissionStatus? ordersStatus,
    String? nextOrders,
    bool? hasMoreOrders,
    FormzSubmissionStatus? orderDetailStatus,
    OrderDetailEntity? orderDetail,
    FormzSubmissionStatus? sendApplicationStatus,
    FormzSubmissionStatus? getCurrentOrderStatus,
    CurrentOrderEntity? currentOrder,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      ordersStatus: ordersStatus ?? this.ordersStatus,
      nextOrders: nextOrders ?? this.nextOrders,
      hasMoreOrders: hasMoreOrders ?? this.hasMoreOrders,
      orderDetailStatus: orderDetailStatus ?? this.orderDetailStatus,
      orderDetail: orderDetail ?? this.orderDetail,
      sendApplicationStatus: sendApplicationStatus ?? this.sendApplicationStatus,
      getCurrentOrderStatus: getCurrentOrderStatus ?? this.getCurrentOrderStatus,
      currentOrder: currentOrder ?? this.currentOrder,
    );
  }

  @override
  List<Object?> get props => [
        orders,
        ordersStatus,
        nextOrders,
        hasMoreOrders,
        orderDetailStatus,
        orderDetail,
        sendApplicationStatus,
        getCurrentOrderStatus,
        currentOrder,
      ];
}

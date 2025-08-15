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
  final FormzSubmissionStatus addNewServiceStatus;
  final FormzSubmissionStatus changeOrderStatus;
  final String orderStatus;
  final int orderIdAsSelectedMechanic;
  final FormzSubmissionStatus selectedOrderStatus;
  final SelectedOrderEntity selectedOrder;

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
    this.addNewServiceStatus = FormzSubmissionStatus.initial,
    this.changeOrderStatus = FormzSubmissionStatus.initial,
    this.orderStatus = '',
    this.orderIdAsSelectedMechanic = -1,
    this.selectedOrderStatus = FormzSubmissionStatus.initial,
    this.selectedOrder = const SelectedOrderEntity(),
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
    FormzSubmissionStatus? addNewServiceStatus,
    FormzSubmissionStatus? changeOrderStatus,
    String? orderStatus,
    int? orderIdAsSelectedMechanic,
    FormzSubmissionStatus? selectedOrderStatus,
    SelectedOrderEntity? selectedOrder,
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
      addNewServiceStatus: addNewServiceStatus ?? this.addNewServiceStatus,
      changeOrderStatus: changeOrderStatus ?? this.changeOrderStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      orderIdAsSelectedMechanic: orderIdAsSelectedMechanic ?? this.orderIdAsSelectedMechanic,
      selectedOrderStatus: selectedOrderStatus ?? this.selectedOrderStatus,
      selectedOrder: selectedOrder ?? this.selectedOrder,
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
        addNewServiceStatus,
        changeOrderStatus,
        orderStatus,
        orderIdAsSelectedMechanic,
        selectedOrderStatus,
        selectedOrder,
      ];
}

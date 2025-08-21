part of 'orders_history_bloc.dart';

@immutable
class OrdersHistoryState extends Equatable {
  final FormzSubmissionStatus ordersHistoryStatus;
  final List<OrdersWithDataEntity> ordersHistory;
  final String nextOrdersHistory;
  final bool hasMoreOrdersHistory;
  final FormzSubmissionStatus orderHistoryDetailStatus;
  final CurrentOrderEntity orderHistoryDetail;
  final double totalPrice;

  const OrdersHistoryState({
    this.ordersHistoryStatus = FormzSubmissionStatus.initial,
    this.ordersHistory = const [],
    this.nextOrdersHistory = '',
    this.hasMoreOrdersHistory = true,
    this.orderHistoryDetailStatus = FormzSubmissionStatus.initial,
    this.orderHistoryDetail = const CurrentOrderEntity(),
    this.totalPrice = 0,
  });

  OrdersHistoryState copyWith({
    FormzSubmissionStatus? ordersHistoryStatus,
    List<OrdersWithDataEntity>? ordersHistory,
    String? nextOrdersHistory,
    bool? hasMoreOrdersHistory,
    FormzSubmissionStatus? orderHistoryDetailStatus,
    CurrentOrderEntity? orderHistoryDetail,
    double? totalPrice,
  }) {
    return OrdersHistoryState(
      ordersHistoryStatus: ordersHistoryStatus ?? this.ordersHistoryStatus,
      ordersHistory: ordersHistory ?? this.ordersHistory,
      nextOrdersHistory: nextOrdersHistory ?? this.nextOrdersHistory,
      hasMoreOrdersHistory: hasMoreOrdersHistory ?? this.hasMoreOrdersHistory,
      orderHistoryDetailStatus: orderHistoryDetailStatus ?? this.orderHistoryDetailStatus,
      orderHistoryDetail: orderHistoryDetail ?? this.orderHistoryDetail,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  @override
  List<Object?> get props => [
        ordersHistoryStatus,
        ordersHistory,
        nextOrdersHistory,
        hasMoreOrdersHistory,
        orderHistoryDetailStatus,
        orderHistoryDetail,
        totalPrice,
      ];
}

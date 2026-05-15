part of 'orders_bloc.dart';

enum OrderLifecycleEvent { none, arrived, inProgress, completed }

@immutable
class OrdersState extends Equatable {
  final OrderAccepted? orderAccepted;
  final FormzSubmissionStatus currentOrderStatus;
  final CurrentOrderEntity currentOrder;
  final FormzSubmissionStatus doneOrderStatus;
  final int code;

  // Real-time mechanic position from `new-mechanic-address` WS event.
  // Phase 4 (tracking screen) will use this to redraw the route.
  final double? mechanicLat;
  final double? mechanicLng;

  // Mechanic's extra-work proposal awaiting driver decision.
  // Phase 4 surfaces this in a modal sheet.
  final SubOrderModel? pendingSubOrder;

  // One-shot lifecycle signals for BlocListener navigation
  // (arrived → status badge, inProgress → working UI, completed → finished screen).
  final OrderLifecycleEvent lifecycleEvent;

  const OrdersState({
    this.orderAccepted,
    this.currentOrderStatus = FormzSubmissionStatus.initial,
    this.currentOrder = const CurrentOrderEntity(),
    this.doneOrderStatus = FormzSubmissionStatus.initial,
    this.code = -1,
    this.mechanicLat,
    this.mechanicLng,
    this.pendingSubOrder,
    this.lifecycleEvent = OrderLifecycleEvent.none,
  });

  OrdersState copyWith({
    OrderAccepted? orderAccepted,
    FormzSubmissionStatus? currentOrderStatus,
    CurrentOrderEntity? currentOrder,
    FormzSubmissionStatus? doneOrderStatus,
    int? code,
    double? mechanicLat,
    double? mechanicLng,
    SubOrderModel? pendingSubOrder,
    OrderLifecycleEvent? lifecycleEvent,
  }) {
    return OrdersState(
      orderAccepted: orderAccepted ?? this.orderAccepted,
      currentOrderStatus: currentOrderStatus ?? this.currentOrderStatus,
      currentOrder: currentOrder ?? this.currentOrder,
      doneOrderStatus: doneOrderStatus ?? this.doneOrderStatus,
      code: code ?? this.code,
      mechanicLat: mechanicLat ?? this.mechanicLat,
      mechanicLng: mechanicLng ?? this.mechanicLng,
      pendingSubOrder: pendingSubOrder ?? this.pendingSubOrder,
      lifecycleEvent: lifecycleEvent ?? this.lifecycleEvent,
    );
  }

  OrdersState clearPendingSubOrder() {
    return OrdersState(
      orderAccepted: orderAccepted,
      currentOrderStatus: currentOrderStatus,
      currentOrder: currentOrder,
      doneOrderStatus: doneOrderStatus,
      code: code,
      mechanicLat: mechanicLat,
      mechanicLng: mechanicLng,
      pendingSubOrder: null,
      lifecycleEvent: lifecycleEvent,
    );
  }

  OrdersState clearLifecycleEvent() {
    return OrdersState(
      orderAccepted: orderAccepted,
      currentOrderStatus: currentOrderStatus,
      currentOrder: currentOrder,
      doneOrderStatus: doneOrderStatus,
      code: code,
      mechanicLat: mechanicLat,
      mechanicLng: mechanicLng,
      pendingSubOrder: pendingSubOrder,
      lifecycleEvent: OrderLifecycleEvent.none,
    );
  }

  @override
  List<Object?> get props => [
    orderAccepted,
    currentOrderStatus,
    currentOrder,
    doneOrderStatus,
    code,
    mechanicLat,
    mechanicLng,
    pendingSubOrder,
    lifecycleEvent,
  ];
}

class OrderCanceled extends OrdersState {
  // Cancel keyin home `state.currentOrderStatus`'ni initial deb topib
  // shimmer'da qotirib qo'ymasligi uchun success + bo'sh order bilan
  // boshlanadi (id=-1). `is OrderCanceled` tekshiruvlari hali ham
  // ishlaydi — bu sub-class identity'i listenWhen filterlarida kerak.
  const OrderCanceled()
      : super(
          currentOrderStatus: FormzSubmissionStatus.success,
          currentOrder: const CurrentOrderEntity(),
        );
}
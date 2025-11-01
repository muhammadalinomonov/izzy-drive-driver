import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';
import 'package:taxi_app/src/core/utils/my_functions.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_button.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_image.dart';
import 'package:taxi_app/src/features/profile/presentation/bloc/history/orders_history_bloc.dart';
import 'package:taxi_app/src/features/profile/presentation/widgets/map_widget.dart';
import 'package:taxi_app/src/features/profile/presentation/widgets/order_information_widget.dart';

class OrderHistorySingleScreen extends StatefulWidget {
  const OrderHistorySingleScreen({super.key, required this.orderId, this.fromHistory = true});

  final int orderId;
  final bool fromHistory;

  @override
  State<OrderHistorySingleScreen> createState() => _OrderHistorySingleScreenState();
}

class _OrderHistorySingleScreenState extends State<OrderHistorySingleScreen> {
  late OrdersHistoryBloc _ordersHistoryBloc;

  @override
  void initState() {
    super.initState();

    _ordersHistoryBloc = OrdersHistoryBloc()..add(GetOrderHistoryDetailEvent(orderId: widget.orderId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _ordersHistoryBloc,
      child: Scaffold(
        backgroundColor: AppColor.lightBlue,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: widget.fromHistory
            ? null
            : CommonButton(
                text: 'Asosiyga qaytish',
                margin: EdgeInsets.symmetric(horizontal: 12),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
        body: Stack(
          children: [
            BlocBuilder<OrdersHistoryBloc, OrdersHistoryState>(
              builder: (context, state) {
                if (state.orderHistoryDetailStatus.isSuccess) {
                  return SizedBox(
                    height: 358,
                    child: OrderMapWidget(
                      fromPoint: state.orderHistoryDetail.map.startPoint.toPoint(),
                      toPoint: state.orderHistoryDetail.map.endPoint.toPoint(),
                      routePoints: state.orderHistoryDetail.map.route.map((e) => [e.lat, e.lng]).toList(),
                    ),
                  );
                }
                return SizedBox();
              },
            ),
            BlocBuilder<OrdersHistoryBloc, OrdersHistoryState>(
              builder: (context, state) {
                if (state.orderHistoryDetailStatus.isInProgress) {
                  return Center(child: CircularProgressIndicator.adaptive());
                } else if (state.orderHistoryDetailStatus.isFailure) {
                  return SizedBox();
                }
                if (state.orderHistoryDetailStatus.isSuccess) {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 269 + context.padding.top),
                        if (widget.fromHistory)
                          Container(
                            width: context.sizeOf.width,
                            padding: EdgeInsets.only(top: context.padding.top + 12, right: 27, left: 12, bottom: 18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                              color: AppColor.white,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 22),
                                Text(
                                  MyFunctions.formatDateTime(state.orderHistoryDetail.completedTime.formattedTime),
                                  style: context.textTheme.bodyMedium!.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.blueMain
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            width: context.sizeOf.width,
                            padding: EdgeInsets.only(top: context.padding.top + 18, right: 27, left: 27, bottom: 18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                              color: AppColor.white,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // SvgPicture.asset(AppIcons.circularCheck, width: 50, height: 50),
                                SizedBox(height: 18),
                                Text(
                                  'Muvaffaqiyatli yakunlandi!',
                                  style: context.textTheme.bodyMedium!.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Lorem Ipsum is simply dummy text of the printing and typesetting industry',
                                  style: context.textTheme.bodySmall!.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: AppColor.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColor.white),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Haydovchi ma’lumotlari',
                                style: context.textTheme.bodyMedium!.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  CommonNetworkImage(
                                    imageUrl: state.orderHistoryDetail.selectedMechanic.photo,
                                    width: 44,
                                    height: 44,
                                    radius: 22,
                                    fit: BoxFit.cover,
                                  ),
                                  SizedBox(width: 12),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        state.orderHistoryDetail.selectedMechanic.fullName,
                                        style: context.textTheme.bodyMedium!.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        state.orderHistoryDetail.selectedMechanic.phoneNumber,
                                        style: context.textTheme.bodySmall!.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: AppColor.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        OrderInformationWidget(
                          createdAt: MyFunctions.formatDateTime(state.orderHistoryDetail.acceptedAt),
                          workDuration: state.orderHistoryDetail.completedTime.formattedTime,
                          address: state.orderHistoryDetail.currentAddress.address,
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 8),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                          decoration: BoxDecoration(color: AppColor.white, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Xizmatlar',
                                style: context.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 18),
                              Row(
                                children: [
                                  Text(
                                    state.orderHistoryDetail.orderTitle,
                                    style: context.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                      color: AppColor.grey,
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      margin: EdgeInsets.symmetric(horizontal: 8),
                                      color: AppColor.lightBlue,
                                      height: 1,
                                    ),
                                  ),
                                  Text(
                                    '\$${state.orderHistoryDetail.price}',
                                    style: context.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              ...List.generate(
                                state.orderHistoryDetail.subOrders
                                    .where((element) => element.status == 'accepted')
                                    .length,
                                (index) {
                                  final subOrder = state.orderHistoryDetail.subOrders
                                      .where((element) => element.status == 'accepted')
                                      .toList()[index];
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: index == 3 - 1 ? 0 : 12),
                                    child: Row(
                                      children: [
                                        Text(
                                          subOrder.title,
                                          style: context.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w400,
                                            fontSize: 14,
                                            color: AppColor.grey,
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            margin: EdgeInsets.symmetric(horizontal: 8),
                                            color: AppColor.lightBlue,
                                            height: 1,
                                          ),
                                        ),
                                        Text(
                                          '\$${subOrder.price}',
                                          style: context.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 8),
                                padding: EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: AppColor.darkBlue,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Umumiy summa',
                                      style: context.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14,
                                        color: AppColor.blueMain,
                                      ),
                                    ),
                                    Text(
                                      '\$${state.orderHistoryDetail.totalPrice}',
                                      style: context.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                        color: AppColor.blueMain,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 88),
                      ],
                    ),
                  );
                } else {
                  return SizedBox();
                }
              },
            ),
            Positioned(
              top: context.padding.top,
              child: IconButton(
                iconSize: 38,
                onPressed: () => context.pop(),
                icon: Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColor.white),
                  child: Icon(Icons.arrow_back, size: 26),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

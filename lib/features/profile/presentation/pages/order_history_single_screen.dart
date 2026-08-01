import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/core/location_service.dart';
import 'package:taxi_app/core/utils/extensions.dart';
import 'package:taxi_app/core/utils/my_functions.dart';
import 'package:taxi_app/features/common/presentation/widgets/common_button.dart';
import 'package:taxi_app/features/common/presentation/widgets/common_image.dart';
import 'package:taxi_app/features/common/presentation/widgets/common_scalel_animation.dart';
import 'package:taxi_app/features/master/data/repository/master_repository_impl.dart';
import 'package:taxi_app/features/master/data/source/master_remote_data_source.dart';
import 'package:taxi_app/features/master/presentation/bloc/master_bloc.dart';
import 'package:taxi_app/features/master/presentation/screens/master_detail_sheet.dart';
import 'package:taxi_app/features/order_proccess/presentation/widgets/sub_orders_card.dart';
import 'package:taxi_app/features/profile/presentation/bloc/history/orders_history_bloc.dart';
import 'package:taxi_app/features/profile/presentation/widgets/map_widget.dart';

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
                text: 'Back to home',
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
                      routePoints: state.orderHistoryDetail.map.route.map((e) => [e.lng, e.lat]).toList(),
                      // The order-details card overlays the lower ~90px
                      // of the map (content scrolls in below the 269-px
                      // top spacer). Reserve that as fit-bounds padding
                      // so markers don't end up under the card.
                      bottomInset: 110,
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
                        Container(
                          width: context.sizeOf.width,
                          padding: EdgeInsets.only(top: 12, right: 27, left: 12, bottom: 18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                            color: AppColor.white,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order details',
                                style: context.textTheme.bodyMedium!.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Order placed',
                                style: context.textTheme.bodyMedium!.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: AppColor.grey,
                                ),
                              ),
                              Text(
                                MyFunctions.formatDateTime(state.orderHistoryDetail.acceptedAt),
                                style: context.textTheme.bodyMedium!.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Divider(height: 25, thickness: 1, color: AppColor.lightGrey),
                              Text(
                                'Time spent',
                                style: context.textTheme.bodyMedium!.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: AppColor.grey,
                                ),
                              ),
                              Text(
                                MyFunctions.formatDuration(
                                  state.orderHistoryDetail.completedTime.minutes +
                                      state.orderHistoryDetail.completedTime.days * 1440 +
                                      state.orderHistoryDetail.completedTime.hours * 60,
                                ),
                                style: context.textTheme.bodyMedium!.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (state.orderHistoryDetail.workTimeEstimateMin != null &&
                                  state.orderHistoryDetail.workTimeEstimateMin! > 0) ...[
                                Divider(height: 25, thickness: 1, color: AppColor.lightGrey),
                                Text(
                                  'Estimated work time'.tr(),
                                  style: context.textTheme.bodyMedium!.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: AppColor.grey,
                                  ),
                                ),
                                Text(
                                  '~${state.orderHistoryDetail.workTimeEstimateMin} min',
                                  style: context.textTheme.bodyMedium!.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              Divider(height: 25, thickness: 1, color: AppColor.lightGrey),
                              Text(
                                'Destination',
                                style: context.textTheme.bodyMedium!.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: AppColor.grey,
                                ),
                              ),
                              Text(
                                state.orderHistoryDetail.address,
                                style: context.textTheme.bodyMedium!.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Divider(height: 25, thickness: 1, color: AppColor.lightGrey),
                              Text(
                                'Payment type',
                                style: context.textTheme.bodyMedium!.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: AppColor.grey,
                                ),
                              ),
                              Text(
                                'Cash',
                                style: context.textTheme.bodyMedium!.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
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
                                'Master',
                                style: context.textTheme.bodyMedium!.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  AvatarImage(
                                    imageUrl: state.orderHistoryDetail.mechanicInfo.photo,
                                    name: state.orderHistoryDetail.mechanicInfo.mechanicName,
                                    size: 44,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          state.orderHistoryDetail.mechanicInfo.mechanicName,
                                          style: context.textTheme.bodyMedium!.copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        if (state.orderHistoryDetail.mechanicInfo.phoneNumber.isNotEmpty)
                                          Text(
                                            state.orderHistoryDetail.mechanicInfo.phoneNumber,
                                            style: context.textTheme.bodySmall!.copyWith(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w400,
                                              color: AppColor.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  CommonScaleAnimation(
                                    onTap: () {
                                      final masterBloc = MasterBloc(
                                        MasterRepositoryImpl(MasterRemoteDataSource()),
                                        LocationService(),
                                      );
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (context) => BlocProvider.value(
                                          value: masterBloc,
                                          child: MasterDetailSheet(id: state.orderHistoryDetail.mechanicInfo.mechanicId),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: AppColor.lightBlue,
                                      ),
                                      child: Text(
                                        'More',
                                        style: context.textTheme.bodyMedium!.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        ///
                        SubOrdersCard(currentOrder: state.orderHistoryDetail.toCurrentOrderEntity()),
                        // Container(
                        //   margin: EdgeInsets.only(top: 8),
                        //   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                        //   decoration: BoxDecoration(color: AppColor.white, borderRadius: BorderRadius.circular(12)),
                        //   child: Column(
                        //     mainAxisSize: MainAxisSize.min,
                        //     crossAxisAlignment: CrossAxisAlignment.start,
                        //     children: [
                        //       Text(
                        //         'Xizmatlar',
                        //         style: context.textTheme.bodyMedium?.copyWith(
                        //           fontWeight: FontWeight.w500,
                        //           fontSize: 16,
                        //         ),
                        //       ),
                        //       SizedBox(height: 18),
                        //       Row(
                        //         children: [
                        //           Text(
                        //             state.orderHistoryDetail.orderTitle,
                        //             style: context.textTheme.bodyMedium?.copyWith(
                        //               fontWeight: FontWeight.w400,
                        //               fontSize: 14,
                        //               color: AppColor.grey,
                        //             ),
                        //           ),
                        //           Expanded(
                        //             child: Container(
                        //               margin: EdgeInsets.symmetric(horizontal: 8),
                        //               color: AppColor.lightBlue,
                        //               height: 1,
                        //             ),
                        //           ),
                        //           Text(
                        //             '\$${state.orderHistoryDetail.price}',
                        //             style: context.textTheme.bodyMedium?.copyWith(
                        //               fontWeight: FontWeight.w500,
                        //               fontSize: 14,
                        //             ),
                        //           ),
                        //         ],
                        //       ),
                        //       SizedBox(height: 16),
                        //       ...List.generate(
                        //         state.orderHistoryDetail.subOrders
                        //             .where((element) => element.status == 'accepted')
                        //             .length,
                        //         (index) {
                        //           final subOrder = state.orderHistoryDetail.subOrders
                        //               .where((element) => element.status == 'accepted')
                        //               .toList()[index];
                        //           return Padding(
                        //             padding: EdgeInsets.only(bottom: index == 3 - 1 ? 0 : 12),
                        //             child: Row(
                        //               children: [
                        //                 Text(
                        //                   subOrder.title,
                        //                   style: context.textTheme.bodyMedium?.copyWith(
                        //                     fontWeight: FontWeight.w400,
                        //                     fontSize: 14,
                        //                     color: AppColor.grey,
                        //                   ),
                        //                 ),
                        //                 Expanded(
                        //                   child: Container(
                        //                     margin: EdgeInsets.symmetric(horizontal: 8),
                        //                     color: AppColor.lightBlue,
                        //                     height: 1,
                        //                   ),
                        //                 ),
                        //                 Text(
                        //                   '\$${subOrder.price}',
                        //                   style: context.textTheme.bodyMedium?.copyWith(
                        //                     fontWeight: FontWeight.w500,
                        //                     fontSize: 14,
                        //                   ),
                        //                 ),
                        //               ],
                        //             ),
                        //           );
                        //         },
                        //       ),
                        //       Container(
                        //         margin: EdgeInsets.only(top: 8),
                        //         padding: EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        //         decoration: BoxDecoration(
                        //           borderRadius: BorderRadius.circular(12),
                        //           color: AppColor.darkBlue,
                        //         ),
                        //         child: Row(
                        //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //           children: [
                        //             Text(
                        //               'Umumiy summa',
                        //               style: context.textTheme.bodyMedium?.copyWith(
                        //                 fontWeight: FontWeight.w400,
                        //                 fontSize: 14,
                        //                 color: AppColor.blueMain,
                        //               ),
                        //             ),
                        //             Text(
                        //               '\$${state.orderHistoryDetail.totalPrice}',
                        //               style: context.textTheme.bodyMedium?.copyWith(
                        //                 fontWeight: FontWeight.w500,
                        //                 fontSize: 16,
                        //                 color: AppColor.blueMain,
                        //               ),
                        //             ),
                        //           ],
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),
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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/common/presentation/widgets/paginator.dart';
import 'package:mechanic/features/profile/presentation/blocs/history/orders_history_bloc.dart';

import 'order_history_single_screen.dart';

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  late OrdersHistoryBloc _ordersHistoryBloc;

  @override
  void initState() {
    _ordersHistoryBloc = OrdersHistoryBloc()
      ..add(GetOrdersHistoryEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _ordersHistoryBloc,
      child: Scaffold(
        body: BlocBuilder<OrdersHistoryBloc, OrdersHistoryState>(
          builder: (context, state) {
            if (state.ordersHistoryStatus.isInProgress) {
              return Center(child: CircularProgressIndicator.adaptive());
            }
            return Column(
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.only(top: context.padding.top + 12, left: 12, right: 12, bottom: 18),
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(context).pop(),
                            child: Icon(Icons.arrow_back, size: 24),
                          ),
                          Text(
                            'Buyurtmalar tarixi',
                            style: context.textTheme.titleLarge!.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 24)
                        ],
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 6.5, horizontal: 12),
                        decoration: BoxDecoration(
                          color: solitude,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Umumiy daromad',
                              style: context.textTheme.bodyMedium!.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: gray4,
                              ),
                            ),
                            Text(
                              '\$${state.totalPrice}',
                              style: context.textTheme.bodyMedium!.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: Paginator(
                    onRefresh: () async {
                      _ordersHistoryBloc.add(GetOrdersHistoryEvent());
                    },
                    status: state.ordersHistoryStatus,
                    hasMoreReach: state.hasMoreOrdersHistory,
                    onLoadMore: () {
                      _ordersHistoryBloc.add(GetMoreOrdersHistoryEvent());
                    },
                    itemCount: state.ordersHistory.length,
                    separator: (context, index) => SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final orders = state.ordersHistory[index];
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              orders.date,
                              style: context.textTheme.bodyMedium!.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(height: 4),
                            ...List.generate(
                              orders.orders.length,
                                  (index) {
                                final order = orders.orders[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(CupertinoPageRoute(
                                      builder: (context) =>
                                          BlocProvider.value(
                                            value: _ordersHistoryBloc,
                                            child: OrderHistorySingleScreen(orderId: order.id),
                                          ),
                                    ));
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(12),
                                    margin: EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: solitude),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                orders.date,
                                                style: context.textTheme.bodyMedium!.copyWith(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                order.address,
                                                style: context.textTheme.bodyMedium!.copyWith(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '\$${order.orderPrice}',
                                            style: context.textTheme.bodyMedium!.copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

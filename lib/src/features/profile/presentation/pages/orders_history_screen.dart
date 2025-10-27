import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';
import 'package:taxi_app/src/core/utils/my_functions.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/paginator.dart';
import 'package:taxi_app/src/features/profile/presentation/bloc/history/orders_history_bloc.dart';
import 'package:taxi_app/src/features/profile/presentation/widgets/order_history_item.dart';
import 'package:taxi_app/src/routes/pages.dart';

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  late OrdersHistoryBloc _ordersHistoryBloc;

  @override
  void initState() {
    _ordersHistoryBloc = OrdersHistoryBloc()..add(GetOrdersHistoryEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _ordersHistoryBloc,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColor.white,
          leading: IconButton(onPressed: () => context.pop(), icon: Icon(Icons.arrow_back)),
        ),
        body: BlocBuilder<OrdersHistoryBloc, OrdersHistoryState>(
          builder: (context, state) {
            if (state.ordersHistoryStatus.isInProgress) {
              return Center(child: CircularProgressIndicator.adaptive());
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buyurtmalar tarixi',
                    style: context.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600, fontSize: 20),
                  ),
                  SizedBox(height: 24),
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
                        final item = state.ordersHistory[index];
                        return GestureDetector(
                          onTap: () {
                            context.push(Pages.orderHistoryDetail, extra: {'id': item.id});
                          },
                          child: OrderHistoryItem(
                            date: MyFunctions.formatDateTime(item.createdAt),
                            address: item.currentAddress.address,
                            price: item.price,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

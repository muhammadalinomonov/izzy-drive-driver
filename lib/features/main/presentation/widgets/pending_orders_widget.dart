import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanic/assets/constants/images.dart';
import 'package:mechanic/core/utils/my_functions.dart';
import 'package:mechanic/features/common/presentation/widgets/empty_widget.dart';
import 'package:mechanic/features/common/presentation/widgets/paginator.dart';
import 'package:mechanic/features/main/presentation/blocs/orders/orders_bloc.dart';
import 'package:mechanic/features/main/presentation/screens/order_single_screen.dart';
import 'package:mechanic/features/main/presentation/widgets/bottomsheets/selected_order_sheet.dart';
import 'package:mechanic/features/main/presentation/widgets/order_item.dart';

class PendingOrdersWidget extends StatelessWidget {
  const PendingOrdersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrdersBloc, OrdersState>(
      listenWhen: (previous, current) => previous.orderIdAsSelectedMechanic != current.orderIdAsSelectedMechanic,
      listener: (context, state) {
        showModalBottomSheet(
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          context: context,
          builder: (context) {
            return SelectedOrderSheet(id: state.orderIdAsSelectedMechanic);
          },
        );
      },
      builder: (context, state) {
        return Paginator(
          onRefresh: () async {
            context.read<OrdersBloc>().add(GetOrdersEvent());
          },
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          separator: (context, index) => SizedBox(height: 12),
          errorWidget: Center(
            child: Text(
              'Xatolik yuz berdi',
              style: TextStyle(color: Colors.red),
            ),
          ),
          itemBuilder: (context, index) {
            final order = state.orders[index];
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => OrderSingleScreen(orderId: order.id),
                  ),
                );
              },
              child: OrderItem(
                title: order.orderTitle,
                distance: order.distanceKm.toString(),
                price: MyFunctions.formatCost(order.price),
                createdAt: order.createdAt,
                isYouSentRequest: order.proposal.id != -1,
              ),
            );
          },
          emptyWidget: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: EmptyWidget(
              icon: AppImages.emptyOrder,
              imageHeight: 200,
              imageWidth: 200,
              title: 'Hozircha aktiv buyurtmalar yo’q',
              subtitle: 'Odatda, yangi buyurtmalar 10-15 daqiqa ichida paydo bo’ladi.',
            ),
          ),
          itemCount: state.orders.length,
          status: state.ordersStatus,
          hasMoreReach: state.hasMoreOrders,
          onLoadMore: () {
            context.read<OrdersBloc>().add(GetMoreOrdersEvent());
          },
        );
      },
    );
  }
}

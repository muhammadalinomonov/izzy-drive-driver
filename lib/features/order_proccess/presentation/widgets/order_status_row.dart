import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/core/constants/color/app_icons.dart';
import 'package:taxi_app/features/order_proccess/presentation/bloc/orders_bloc.dart';
import 'package:taxi_app/features/order_proccess/presentation/widgets/order_status_row_item.dart';

class OrderStatusRow extends StatelessWidget {
  const OrderStatusRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        final status = state.currentOrder.status;
        return Row(
          children: [
            OrderStatusRowItem(
              isDone: !status.isPending && !status.isMechanicSelected && !status.isAccepted,
              isActive: !status.isMechanicSelected,
              icon: AppIcons.rocket,
            ),
            Expanded(child: Container(height: 2, color: const Color(0xffCDD8EA))),
            OrderStatusRowItem(
              isDone: !status.isPending && !status.isMechanicSelected && !status.isArrived && !status.isAccepted,
              isActive: status.isArrived,
              icon: AppIcons.location,
            ),
            Expanded(child: Container(height: 2, color: const Color(0xffCDD8EA))),
            OrderStatusRowItem(
              isDone: !status.isPending && !status.isMechanicSelected && !status.isArrived && !status.isInProgress && !status.isAccepted,
              isActive: status.isInProgress,
              icon: AppIcons.key,
            ),
            Expanded(child: Container(height: 2, color: const Color(0xffCDD8EA))),
            OrderStatusRowItem(isDone: false, isActive: status.isMechanicDone, icon: AppIcons.finishflag),
          ],
        );
      },
    );
  }
}

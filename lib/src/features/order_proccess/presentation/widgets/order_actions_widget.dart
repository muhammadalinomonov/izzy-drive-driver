import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/bloc/orders_bloc.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/order_action_item.dart';
import 'package:taxi_app/src/routes/pages.dart';
import 'package:url_launcher/url_launcher_string.dart';

class OrderActionsWidget extends StatelessWidget {
  const OrderActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OrderActionItem(
              icon: AppIcons.call,
              text: 'Call',
              onTap: () async {
                if (await canLaunchUrlString('tel:${state.currentOrder.selectedMechanic.phoneNumber}')) {
                  await launchUrlString('tel:${state.currentOrder.selectedMechanic.phoneNumber}');
                }
              },
            ),
            OrderActionItem(
              icon: AppIcons.info,
              text: 'Order About',
              onTap: () {
                context.push(Pages.orderInfo);
              },
            ),
            if (state.currentOrder.status.isPending ||
                state.currentOrder.status.isAccepted && state.currentOrder.status.isArrived)
              OrderActionItem(
                icon: AppIcons.x,
                text: 'Cancel',
                onTap: () {
                  context.read<OrdersBloc>().add(CancelOrderEvent());
                },
              ),
          ],
        );
      },
    );
  }
}

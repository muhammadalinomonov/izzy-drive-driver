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

  Future<void> _confirmCancel(BuildContext context) async {
    final bloc = context.read<OrdersBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel order?'),
        content: const Text('Are you sure you want to cancel the order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    bloc.add(CancelOrderEvent());
    if (!context.mounted) return;
    context.go(Pages.main);
  }

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
                final phone = state.currentOrder.selectedMechanic.phoneNumber;
                if (phone.isEmpty) return;
                if (await canLaunchUrlString('tel:$phone')) {
                  await launchUrlString('tel:$phone');
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
                state.currentOrder.status.isAccepted ||
                state.currentOrder.status.isArrived)
              OrderActionItem(
                icon: AppIcons.x,
                text: 'Cancel',
                onTap: () => _confirmCancel(context),
              ),
          ],
        );
      },
    );
  }
}
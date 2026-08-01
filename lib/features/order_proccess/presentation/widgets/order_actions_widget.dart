import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/core/constants/color/app_icons.dart';
import 'package:taxi_app/features/cancel_reasons/presentation/widgets/cancel_reason_sheet.dart';
import 'package:taxi_app/features/order_proccess/presentation/bloc/orders_bloc.dart';
import 'package:taxi_app/features/order_proccess/presentation/widgets/order_action_item.dart';
import 'package:taxi_app/routes/pages.dart';
import 'package:url_launcher/url_launcher_string.dart';

class OrderActionsWidget extends StatelessWidget {
  const OrderActionsWidget({super.key});

  Future<void> _confirmCancel(BuildContext context) async {
    final bloc = context.read<OrdersBloc>();
    final choice = await showCancelReasonSheet(context);
    if (choice == null || !context.mounted) return;
    bloc.add(CancelOrderEvent(
      reasonId: choice.reasonId,
      reasonText: choice.customText,
    ));
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
                if (phone.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mechanic phone is not available')),
                    );
                  }
                  return;
                }
                if (await canLaunchUrlString('tel:$phone')) {
                  await launchUrlString('tel:$phone');
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open dialer')),
                  );
                }
              },
            ),
            OrderActionItem(
              icon: AppIcons.info,
              text: 'Order About',
              // Pending sub-order'lar soni - orange badge "Order About"
              // tugmasi ustida ko'rinadi, foydalanuvchini diqqatini tortadi.
              badgeCount: state.currentOrder.subOrders
                  .where((s) => s.status.toLowerCase() == 'pending')
                  .length,
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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_image.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/bloc/orders_bloc.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/order_action_item.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/order_info_card.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/sub_orders_card.dart';
import 'package:taxi_app/src/routes/pages.dart';
import 'package:url_launcher/url_launcher_string.dart';

class OrderInfoScreen extends StatefulWidget {
  const OrderInfoScreen({super.key});

  @override
  State<OrderInfoScreen> createState() => _OrderInfoScreenState();
}

class _OrderInfoScreenState extends State<OrderInfoScreen> {
  Future<void> _confirmCancel(BuildContext context) async {
    final bloc = context.read<OrdersBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel order?'),
        content: const Text('Are you sure you want to cancel the order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    bloc.add(CancelOrderEvent());
    if (!mounted) return;
    context.go(Pages.main);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.lightBlue,
      bottomNavigationBar: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          return Container(
            width: MediaQuery.sizeOf(context).width,
            padding: EdgeInsets.only(top: 12, bottom: MediaQuery.paddingOf(context).bottom + 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              color: AppColor.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
                if (state.currentOrder.status.isPending ||
                    state.currentOrder.status.isAccepted ||
                    state.currentOrder.status.isArrived) ...[
                  SizedBox(width: 32),
                  OrderActionItem(
                    icon: AppIcons.x,
                    text: 'Cancel',
                    onTap: () => _confirmCancel(context),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      body: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          return Column(
            children: [
              Container(
                padding: EdgeInsets.only(left: 12, bottom: 18, right: 12),
                width: MediaQuery.sizeOf(context).width,
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.paddingOf(context).top),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Icon(Icons.arrow_back),
                    ),
                    SizedBox(height: 12),
                    Text(
                      state.currentOrder.status.orderDescription,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(top: 8),
                decoration: BoxDecoration(color: AppColor.white, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Master',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        AvatarImage(
                          imageUrl: state.currentOrder.selectedMechanic.photo,
                          size: 44,
                        ),
                        SizedBox(width: 8),
                        Text(
                          state.currentOrder.selectedMechanic.fullName,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), color: AppColor.lightBlue),
                          child: Text(
                            'More',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w500, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              OrderInfoCard(currentOrder: state.currentOrder),

              SubOrdersCard(currentOrder: state.currentOrder),
            ],
          );
        },
      ),
    );
  }
}

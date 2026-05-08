import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/features/order_proccess/domain/entities/current_order_entity.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/bloc/orders_bloc.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/sub_order_item.dart';

class SubOrdersCard extends StatelessWidget {
  const SubOrdersCard({super.key, required this.currentOrder});

  final CurrentOrderEntity currentOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColor.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Services',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SubOrderItem(
            name: currentOrder.orderTitle,
            price: '\$${currentOrder.price}',
            status: '',
            onAction: (bool isAccepted) {},
          ),
          ...List.generate(currentOrder.subOrders.length, (index) {
            final subOrder = currentOrder.subOrders[index];
            return SubOrderItem(
              name: subOrder.title,
              price: '\$${subOrder.price}',
              status: subOrder.status,
              onAction: (bool isAccepted) {
                context.read<OrdersBloc>().add(
                  ChangeSubOrderStatusEvent(id: subOrder.id, status: isAccepted ? 'accepted' : 'cancelled'),
                );
              },
            );
          }),

          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Color(0xffE0F0FF)),
            child: Row(
              children: [
                Text(
                  'Total amount',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w400, color: AppColor.darkBlue),
                ),
                Spacer(),
                SvgPicture.asset(AppIcons.check),
                Text(
                  ' \$${currentOrder.totalPrice}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(fontSize: 16, fontWeight: FontWeight.w500, color: AppColor.blueMain),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

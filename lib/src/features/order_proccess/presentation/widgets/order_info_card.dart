import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/utils/my_functions.dart';
import 'package:taxi_app/src/features/order_proccess/domain/entities/current_order_entity.dart';

class OrderInfoCard extends StatelessWidget {
  const OrderInfoCard({super.key, required this.currentOrder});

  final CurrentOrderEntity currentOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width,
      margin: EdgeInsets.only(top: 8, bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColor.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Buyurtma ma’lumotlari',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          Text(
            'Buyurtma berildi',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 12, fontWeight: FontWeight.w400),
          ),
          SizedBox(height: 4),
          Text(
            MyFunctions.formatDateTime(currentOrder.acceptedAt),
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Divider(color: AppColor.lightBlue),
          if (currentOrder.status.isMechanicDone || currentOrder.status.isCompleted) ...[
            Text(
              'Sarflangan vaqt',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 12, fontWeight: FontWeight.w400),
            ),
            SizedBox(height: 4),
            Builder(
              builder: (context) {
                final completedAt = DateTime.tryParse(currentOrder.completedAt) ?? DateTime.now();
                final acceptedAt = DateTime.tryParse(currentOrder.acceptedAt) ?? DateTime.now();

                final difference = completedAt.difference(acceptedAt);
                return Text(
                  MyFunctions.formatDuration(difference.inMinutes),
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                );
              },
            ),
            Divider(color: AppColor.lightBlue),
          ],
          Text(
            'Qayerga',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 12, fontWeight: FontWeight.w400),
          ),
          SizedBox(height: 4),
          Text(
            currentOrder.currentAddress.address,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
          ),


          if (currentOrder.status.isMechanicDone || currentOrder.status.isCompleted) ...[
            Divider(color: AppColor.lightBlue),
            Text(
              'To’lov turi',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 12, fontWeight: FontWeight.w400),
            ),
            SizedBox(height: 4),
            Text(
              'Naqd pul',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}

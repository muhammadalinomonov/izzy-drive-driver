import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/bloc/orders_bloc.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/order_state_panel.dart';

/// Mexanik ish boshladi - Figma 1900:6171 / 1948:4993.
class InProgressSheet extends StatelessWidget {
  const InProgressSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<OrdersBloc, OrdersState, int?>(
      selector: (state) => state.currentOrder.workTimeEstimateMin,
      builder: (context, minutes) {
        return OrderStatePanel(
          title: 'The master started, estimated work time'.tr(),
          infoLabel: 'Estimated work time'.tr(),
          infoValue: (minutes != null && minutes > 0)
              ? '$minutes ${'min'.tr()}'
              : '-',
        );
      },
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/features/order_proccess/presentation/bloc/orders_bloc.dart';
import 'package:taxi_app/features/order_proccess/presentation/widgets/order_state_panel.dart';

/// Mexanik joyga keldi va ish boshlashga tayyor - Figma frame 1897:4828.
class ArrivedSheet extends StatelessWidget {
  const ArrivedSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<OrdersBloc, OrdersState, int?>(
      selector: (state) => state.currentOrder.workTimeEstimateMin,
      builder: (context, minutes) {
        return OrderStatePanel(
          title: 'The master has arrived and will start soon.'.tr(),
          infoLabel: 'Estimated work time'.tr(),
          infoValue: (minutes != null && minutes > 0)
              ? '$minutes ${'min'.tr()}'
              : '-',
        );
      },
    );
  }
}

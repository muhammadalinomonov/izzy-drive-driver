import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/bloc/orders_bloc.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/order_state_panel.dart';
import 'package:taxi_app/src/features/order_proccess/utils/tracking_calculator.dart';

/// Mexanik buyurtmani qabul qildi va yo'lda - Figma frame 1884:4489.
class TrackingSheet extends StatelessWidget {
  const TrackingSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<OrdersBloc, OrdersState, int>(
      selector: (state) {
        final lat = state.mechanicLat;
        final lng = state.mechanicLng;
        final map = state.currentOrder.map;
        if (lat == null || lng == null) return map.durationMin.ceil();
        return etaMinutes(
          lat, lng, map.endPoint.lat, map.endPoint.lng,
          map.durationMin, map.distanceKm,
        );
      },
      builder: (context, eta) {
        return OrderStatePanel(
          title: 'The master accepted the order and is on the way!'.tr(),
          infoLabel: 'Arrival time'.tr(),
          infoValue: etaLabel(eta),
        );
      },
    );
  }
}

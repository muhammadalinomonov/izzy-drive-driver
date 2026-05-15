import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/location_service.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_image.dart';
import 'package:taxi_app/src/features/master/data/repository/master_repository_impl.dart';
import 'package:taxi_app/src/features/master/data/source/master_remote_data_source.dart';
import 'package:taxi_app/src/features/master/presentation/bloc/master_bloc.dart';
import 'package:taxi_app/src/features/master/presentation/screens/master_detail_sheet.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/bloc/orders_bloc.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/order_actions_widget.dart';
import 'package:taxi_app/src/features/order_proccess/presentation/widgets/order_status_row.dart';
import 'package:taxi_app/src/features/order_proccess/utils/tracking_calculator.dart';

class TrackingSheet extends StatelessWidget {
  const TrackingSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 4, width: 42, color: AppColor.grey2),
          const SizedBox(height: 20),
          _EtaRow(),
          const _WorkTimeEstimateRow(),
          const SizedBox(height: 16),
          Divider(height: 1, indent: 14, endIndent: 14, color: AppColor.grey2, thickness: 1),
          const SizedBox(height: 16),
          _MechanicInfoRow(),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 42),
            child: OrderStatusRow(),
          ),
          const SizedBox(height: 32),
          const OrderActionsWidget(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _EtaRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<OrdersBloc, OrdersState, ({int eta, double remainingKm})>(
      selector: (state) {
        final lat = state.mechanicLat;
        final lng = state.mechanicLng;
        final map = state.currentOrder.map;
        // No live mechanic position yet — show the initial backend estimate.
        if (lat == null || lng == null) {
          return (eta: map.durationMin.ceil(), remainingKm: map.distanceKm);
        }
        final remaining = haversineKm(lat, lng, map.endPoint.lat, map.endPoint.lng);
        final eta = etaMinutes(lat, lng, map.endPoint.lat, map.endPoint.lng, map.durationMin, map.distanceKm);
        return (eta: eta, remainingKm: remaining);
      },
      builder: (context, data) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Arrival time'.tr(),
                    style: TextStyle(color: AppColor.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    etaLabel(data.eta),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Distance'.tr(),
                    style: TextStyle(color: AppColor.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${data.remainingKm.toStringAsFixed(1)} km',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WorkTimeEstimateRow extends StatelessWidget {
  const _WorkTimeEstimateRow();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<OrdersBloc, OrdersState, int?>(
      selector: (state) => state.currentOrder.workTimeEstimateMin,
      builder: (context, minutes) {
        if (minutes == null || minutes <= 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(
            children: [
              Icon(Icons.handyman_outlined, size: 16, color: AppColor.grey),
              const SizedBox(width: 6),
              Text(
                'Estimated work time'.tr(),
                style: TextStyle(color: AppColor.grey, fontSize: 12),
              ),
              const Spacer(),
              Text(
                '~$minutes min',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MechanicInfoRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<OrdersBloc, OrdersState, dynamic>(
      selector: (state) => state.currentOrder.selectedMechanic,
      builder: (context, mechanic) {
        final truckInfo = [mechanic.truckMark, mechanic.truckmodel, mechanic.truckYear]
            .where((s) => (s as String).isNotEmpty)
            .join(' ');
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              AvatarImage(imageUrl: mechanic.photo as String, size: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mechanic.fullName as String,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    if (truckInfo.isNotEmpty)
                      Text(
                        truckInfo,
                        style: TextStyle(color: AppColor.grey, fontSize: 12),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final bloc = MasterBloc(
                    MasterRepositoryImpl(MasterRemoteDataSource()),
                    LocationService(),
                  );
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (ctx) => BlocProvider.value(
                      value: bloc,
                      child: MasterDetailSheet(id: mechanic.id as int),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: AppColor.lightBlue,
                  ),
                  child: Text(
                    'More'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

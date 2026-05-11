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

class ArrivedSheet extends StatelessWidget {
  const ArrivedSheet({super.key});

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
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 40),
          const SizedBox(height: 8),
          Text(
            'The master has arrived!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Please go outside to meet the master.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColor.grey, fontSize: 14),
          ),
          const SizedBox(height: 20),
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
                    'More',
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

import 'package:flutter/material.dart';
import 'package:taxi_app/core/di/injection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:formz/formz.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/core/constants/color/app_icons.dart';
import 'package:taxi_app/core/utils/extensions.dart';
import 'package:taxi_app/core/utils/my_functions.dart';
import 'package:taxi_app/features/common/presentation/widgets/paginator.dart';
import 'package:taxi_app/features/profile/presentation/bloc/history/orders_history_bloc.dart';
import 'package:taxi_app/features/profile/presentation/widgets/order_history_item.dart';
import 'package:taxi_app/routes/pages.dart';

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  late OrdersHistoryBloc _ordersHistoryBloc;

  @override
  void initState() {
    _ordersHistoryBloc = getIt<OrdersHistoryBloc>()..add(GetOrdersHistoryEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _ordersHistoryBloc,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColor.white,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(
            'Order history',
            style: context.textTheme.bodyLarge!.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        body: BlocBuilder<OrdersHistoryBloc, OrdersHistoryState>(
          builder: (context, state) {
            if (state.ordersHistoryStatus.isInProgress) {
              return Center(child: CircularProgressIndicator.adaptive());
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Expanded(
                    child: Paginator(
                      onRefresh: () async {
                        // Pull-to-refresh: the platform spinner is enough user
                        // feedback - keep the list rendered underneath instead
                        // of swapping to the central CircularProgressIndicator.
                        _ordersHistoryBloc.add(GetOrdersHistoryEvent(silent: true));
                      },
                      status: state.ordersHistoryStatus,
                      hasMoreReach: state.hasMoreOrdersHistory,
                      onLoadMore: () {
                        _ordersHistoryBloc.add(GetMoreOrdersHistoryEvent());
                      },
                      itemCount: state.ordersHistory.length,
                      separator: (context, index) => SizedBox(height: 8),
                      emptyWidget: _OrdersHistoryEmptyState(),
                      itemBuilder: (context, index) {
                        final item = state.ordersHistory[index];
                        return GestureDetector(
                          onTap: () {
                            context.push(Pages.orderHistoryDetail, extra: {'id': item.id});
                          },
                          child: OrderHistoryItem(
                            date: MyFunctions.formatDateTime(item.createdAt),
                            address: item.currentAddress.address,
                            price: item.price,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OrdersHistoryEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.lightBlue,
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                AppIcons.timePast,
                width: 44,
                height: 44,
                colorFilter: ColorFilter.mode(AppColor.darkGrey, BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No orders yet',
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColor.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your completed orders will appear here',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: AppColor.grey,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

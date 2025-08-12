import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/images.dart';
import 'package:mechanic/core/utils/my_functions.dart';
import 'package:mechanic/features/common/presentation/widgets/empty_widget.dart';
import 'package:mechanic/features/common/presentation/widgets/paginator.dart';
import 'package:mechanic/features/main/presentation/blocs/orders/orders_bloc.dart';
import 'package:mechanic/features/main/presentation/screens/order_single_screen.dart';
import 'package:mechanic/features/main/presentation/widgets/balance_item.dart';
import 'package:mechanic/features/main/presentation/widgets/current_active_order_widget.dart';
import 'package:mechanic/features/main/presentation/widgets/main_screen_user_widget.dart';
import 'package:mechanic/features/main/presentation/widgets/order_item.dart';
import 'package:mechanic/features/main/presentation/widgets/working_status.dart';
import 'package:mechanic/features/profile/presentation/blocs/profile_bloc.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(GetProfileEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: solitude,
      body: BlocListener<ProfileBloc, ProfileState>(
        listenWhen: (previous, current) => previous.getProfileStatus != current.getProfileStatus,
        listener: (context, state) {
          if (state.getProfileStatus.isSuccess && state.user.status == 'online') {
            context.read<OrdersBloc>()
              ..add(GetOrdersEvent())
              ..add(ConnectToWebSocketEvent());
          } else if (state.getProfileStatus.isSuccess && state.user.status == 'onwork') {
            context.read<OrdersBloc>().add(GetCurrentOrderEvent());
          } else if (state.getProfileStatus.isFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Xatolik yuz berdi')),
            );
          }
        },
        child: BlocListener<ProfileBloc, ProfileState>(
          listenWhen: (previous, current) => previous.updateStatusStatus != current.updateStatusStatus,
          listener: (context, state) {
            if (state.updateStatusStatus.isSuccess && state.status == 'online') {
              context.read<OrdersBloc>()
                ..add(GetOrdersEvent())
                ..add(ConnectToWebSocketEvent());
            } else if (state.status == 'offline' && state.updateStatusStatus.isSuccess) {
              context.read<OrdersBloc>().add(DisConnectFromWebSocketEvent());
            }
          },
          child: Column(
            children: [
              SizedBox(height: MediaQuery.paddingOf(context).top + 6),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: MainScreenUserWidget(),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Row(
                  children: [
                    Expanded(child: WorkingStatus()),
                    SizedBox(width: 8),
                    Expanded(child: BalanceItem()),
                  ],
                ),
              ),
              BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, profileState) {
                  if (profileState.getProfileStatus.isSuccess &&
                      (profileState.status == 'online' || profileState.status == 'offline')) {
                    return Expanded(
                      child: Container(
                        height: MediaQuery.sizeOf(context).height,
                        decoration: BoxDecoration(
                          color: white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                        ),
                        child: profileState.status == 'offline'
                            ? Padding(
                                padding: const EdgeInsets.only(left: 50, right: 50, top: 200),
                                child: EmptyWidget(
                                  icon: AppImages.layInSoft,
                                  imageHeight: 200,
                                  imageWidth: 200,
                                  title: 'Siz hozirda oflaynsiz',
                                  subtitle: 'Ishni boshlash uchun, “Ishga chiqish” tugmasini bosing',
                                ),
                              )
                            : BlocBuilder<OrdersBloc, OrdersState>(
                                builder: (context, state) {
                                  if (profileState.status == 'onwork') {
                                    return CurrentActiveOrderWidget();
                                  }
                                  return Paginator(
                                    onRefresh: () async {
                                      context.read<OrdersBloc>().add(GetOrdersEvent());
                                    },
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    separator: (context, index) => SizedBox(height: 12),
                                    errorWidget: Center(
                                      child: Text(
                                        'Xatolik yuz berdi',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                    itemBuilder: (context, index) {
                                      final order = state.orders[index];
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            CupertinoPageRoute(
                                              builder: (context) => OrderSingleScreen(orderId: order.id),
                                            ),
                                          );
                                        },
                                        child: OrderItem(
                                          title: order.orderTitle,
                                          distance: order.distanceKm.toString(),
                                          price: MyFunctions.formatCost(order.price),
                                          createdAt: order.createdAt,
                                          isYouSentRequest: order.proposal.id != -1,
                                        ),
                                      );
                                    },
                                    emptyWidget: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 50),
                                      child: EmptyWidget(
                                        icon: AppImages.emptyOrder,
                                        imageHeight: 200,
                                        imageWidth: 200,
                                        title: 'Hozircha aktiv buyurtmalar yo’q',
                                        subtitle: 'Odatda, yangi buyurtmalar 10-15 daqiqa ichida paydo bo’ladi.',
                                      ),
                                    ),
                                    itemCount: state.orders.length,
                                    status: state.ordersStatus,
                                    hasMoreReach: state.hasMoreOrders,
                                    onLoadMore: () {
                                      context.read<OrdersBloc>().add(GetMoreOrdersEvent());
                                    },
                                  );
                                },
                              ),
                      ),
                    );
                  } else if (profileState.getProfileStatus.isSuccess && profileState.status == 'onwork') {
                    return CurrentActiveOrderWidget();
                  } else if (profileState.getProfileStatus.isInProgress) {
                    return Expanded(child: Center(child: CircularProgressIndicator.adaptive()));
                  } else {
                    return Center(
                      child: Text(
                        profileState.errorMessage ?? 'Xatolik yuz berdi',
                        style: TextStyle(color: red),
                      ),
                    );
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

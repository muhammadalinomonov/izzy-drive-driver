import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/images.dart';
import 'package:mechanic/features/common/presentation/widgets/empty_widget.dart';
import 'package:mechanic/features/main/presentation/blocs/orders/orders_bloc.dart';
import 'package:mechanic/features/main/presentation/screens/finished_order_single_screen.dart';
import 'package:mechanic/features/main/presentation/widgets/balance_item.dart';
import 'package:mechanic/features/main/presentation/widgets/bottomsheets/selected_order_sheet.dart';
import 'package:mechanic/features/main/presentation/widgets/current_active_order_widget.dart';
import 'package:mechanic/features/main/presentation/widgets/main_screen_user_widget.dart';
import 'package:mechanic/features/main/presentation/widgets/order_action_buttons.dart';
import 'package:mechanic/features/main/presentation/widgets/pending_orders_widget.dart';
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
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     showModalBottomSheet(
      //       isScrollControlled: true,
      //       backgroundColor: Colors.transparent,
      //       context: context,
      //       builder: (context) {
      //         return SelectedOrderSheet(id: 30);
      //       },
      //     );
      //   },
      // ),
      bottomNavigationBar: OrderActionButtons(),
      backgroundColor: solitude,
      body: BlocListener<ProfileBloc, ProfileState>(
        listenWhen: (previous, current) => previous.getProfileStatus != current.getProfileStatus,
        listener: (context, state) {
          if (state.getProfileStatus.isSuccess && state.user.status == 'online') {
            context.read<OrdersBloc>()
              ..add(GetOrdersEvent())
              ..add(ConnectToWebSocketEvent());
          } else if (state.getProfileStatus.isSuccess && state.user.status == 'onwork') {
            context.read<OrdersBloc>()
              ..add(GetCurrentOrderEvent())
              ..add(ConnectToWebSocketEvent());
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
                                  return PendingOrdersWidget();
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

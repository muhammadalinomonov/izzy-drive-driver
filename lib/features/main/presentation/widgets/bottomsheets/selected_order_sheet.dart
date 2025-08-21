import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:formz/formz.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/icons.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/common/presentation/widgets/common_button.dart';
import 'package:mechanic/features/main/presentation/blocs/orders/orders_bloc.dart';
import 'package:mechanic/features/main/presentation/widgets/map_widget.dart';
import 'package:mechanic/features/profile/presentation/blocs/profile_bloc.dart';

class SelectedOrderSheet extends StatefulWidget {
  const SelectedOrderSheet({super.key, required this.id});

  final int id;

  @override
  State<SelectedOrderSheet> createState() => _SelectedOrderSheetState();
}

class _SelectedOrderSheetState extends State<SelectedOrderSheet> {
  Timer? _timer;
  int leftTime = 90;

  @override
  void initState() {
    super.initState();

    context.read<OrdersBloc>().add(GetSelectedOrderEvent(orderId: widget.id));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: context.sizeOf.height * 0.85,
      ),
      decoration: BoxDecoration(color: solitude, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: BlocListener<OrdersBloc, OrdersState>(
        listenWhen: (previous, current) => previous.changeOrderStatus != current.changeOrderStatus,
        listener: (context, state) {
          if (state.changeOrderStatus.isSuccess && state.orderStatus == 'accepted') {
            context.read<ProfileBloc>().add(GetProfileEvent());
            context.read<OrdersBloc>().add(GetCurrentOrderEvent());
            Navigator.pop(context);
          } else if (state.changeOrderStatus.isSuccess) {
            context.read<OrdersBloc>().add(GetOrdersEvent());
            Navigator.pop(context);
          }
        },
        child: BlocConsumer<OrdersBloc, OrdersState>(
          listenWhen: (previous, current) => previous.selectedOrderStatus != current.selectedOrderStatus,
          listener: (context, state) {
            if (state.selectedOrderStatus.isSuccess) {
              _timer = Timer.periodic(
                Duration(seconds: 1),
                (timer) {
                  if (leftTime <= 0) {
                    Navigator.pop(context);
                  }
                  setState(() {
                    leftTime -= 1;
                  });
                },
              );
            }
          },
          builder: (context, state) {
            if (state.selectedOrderStatus.isInProgress) {
              return Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: 400),
                child: CircularProgressIndicator.adaptive(),
              );
            }
            if (state.selectedOrderStatus.isSuccess) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 12, left: 13, bottom: 18, right: 12),
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                        bottom: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 22),
                          height: 2,
                          width: 43,
                          decoration: BoxDecoration(color: gray2, borderRadius: BorderRadius.circular(22)),
                        ),
                        Row(
                          children: [
                            SvgPicture.asset(AppIcons.circularCheck),
                            SizedBox(width: 8),
                            Text(
                              'Haydovchi taklifingizga rozi bo’ldi!',
                              style: context.textTheme.bodyMedium!.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: MediaQuery.sizeOf(context).width,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    padding: EdgeInsets.all(12).copyWith(top: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: white,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buyurtma haqida',
                          style: context.textTheme.bodyMedium!.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 17.5),
                        Text(
                          state.selectedOrder.orderTitle,
                          style: context.textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SvgPicture.asset(AppIcons.location),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.selectedOrder.orderAddress,
                                    style: context.textTheme.bodyMedium!.copyWith(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '8 km uzoqlikda',
                                    style: context.textTheme.bodySmall!.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: 18),
                        Container(
                          height: 183,
                          decoration: BoxDecoration(
                            color: solitude,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius:  BorderRadius.circular(12),
                            child: OrderMapWidget(),
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    width: MediaQuery.sizeOf(context).width,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Kelishilgan summa',
                          style: context.textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 14),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: aliceBlue,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Ustani taklifi',
                                style: context.textTheme.bodyMedium!.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: matisse,
                                ),
                              ),
                              Spacer(),
                              SvgPicture.asset(AppIcons.circularCheck, width: 18, height: 18),
                              SizedBox(width: 8),
                              Text(
                                '\$${state.selectedOrder.proposalPrice}',
                                style: context.textTheme.bodyMedium!
                                    .copyWith(fontWeight: FontWeight.w500, fontSize: 16, color: mainColor),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 6),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Stack(
                      children: [
                        CommonButton(
                          isLoading: state.changeOrderStatus.isInProgress,
                          text: 'Qabul qilish',
                          onTap: () {
                            context
                                .read<OrdersBloc>()
                                .add(ChangeOrderStatusEvent(orderId: widget.id, status: 'accepted'));
                          },
                        ),
                        Container(
                          height: 48,
                          width: context.sizeOf.width * (leftTime / 90),
                          decoration: BoxDecoration(
                            color: white.withValues(alpha: .24),
                            borderRadius: BorderRadius.horizontal(left: Radius.circular(50)),
                          ),
                        )
                      ],
                    ),
                  ),
                  CommonButton(
                    isLoading: state.changeOrderStatus.isInProgress,
                    color: gray2,
                    margin: EdgeInsets.only(left: 12, right: 12, bottom: context.padding.bottom + 8),
                    child: SizedBox(
                      width: context.sizeOf.width,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            'Bekor qilish',
                            style: context.textTheme.bodyMedium!.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Positioned(
                            right: 20,
                            child: Row(
                              children: [
                                SvgPicture.asset(AppIcons.star),
                                SizedBox(width: 6),
                                Text(
                                  '-10',
                                  style: context.textTheme.bodyMedium!.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    onTap: () {
                      context.read<OrdersBloc>().add(ChangeOrderStatusEvent(
                            orderId: widget.id,
                            status: 'cancelled',
                          ));
                    },
                  )
                ],
              );
            } else {
              return Container(height: 400);
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }
}

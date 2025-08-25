import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:formz/formz.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/icons.dart';
import 'package:mechanic/assets/constants/images.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/common/presentation/widgets/common_button.dart';
import 'package:mechanic/features/common/presentation/widgets/common_scalel_animation.dart';
import 'package:mechanic/features/common/presentation/widgets/common_text_field.dart';
import 'package:mechanic/features/main/presentation/blocs/orders/orders_bloc.dart';

class OrderSingleBottom extends StatefulWidget {
  const OrderSingleBottom({super.key, required this.orderId});

  final int orderId;

  @override
  State<OrderSingleBottom> createState() => _OrderSingleBottomState();
}

class _OrderSingleBottomState extends State<OrderSingleBottom> {
  final TextEditingController _proposedPriceController = TextEditingController();
  Timer? _timer;
  String timeLeft = '00:00';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrdersBloc, OrdersState>(
      listenWhen: (previous, current) => previous.orderDetailStatus != current.orderDetailStatus,
      listener: (context, state) {
        if (state.orderDetailStatus.isSuccess) {
          final now = DateTime.now();
          final proposalCreatedAt = state.orderDetail.yourProposal.createdAt;
          if (proposalCreatedAt.isNotEmpty) {
            final proposalTime = DateTime.parse(proposalCreatedAt);
            final difference = now.difference(proposalTime);
            if (difference.inMinutes < 5) {
              _timer?.cancel();
              _timer = Timer.periodic(Duration(seconds: 1), (timer) {
                final newDifference = DateTime.now().difference(proposalTime);
                final remainingTime = Duration(minutes: 5) - newDifference;
                setState(() {
                  timeLeft =
                      '${remainingTime.inMinutes.toString().padLeft(2, '0')}:${(remainingTime.inSeconds % 60).toString().padLeft(2, '0')}';
                });
              });
            } else {
              _timer?.cancel();
            }
          }
        }
      },
      child: BlocConsumer<OrdersBloc, OrdersState>(
        listenWhen: (previous, current) => current.sendApplicationStatus != previous.sendApplicationStatus,
        listener: (context, state) {
          if (state.sendApplicationStatus.isSuccess) {
            _proposedPriceController.clear();
            context.read<OrdersBloc>().add(GetOrderDetailEvent(orderId: widget.orderId));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Taklif yuborildi')),
            );
          } else if (state.sendApplicationStatus.isFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Taklif yuborishda xatolik')),
            );
          }
        },
        builder: (context, state) {
          if (state.orderDetailStatus.isSuccess) {
            final now = DateTime.now();
            bool isOpenToSend = true;
            if (state.orderDetail.yourProposal.createdAt.isNotEmpty) {
              final proposalTime = DateTime.parse(state.orderDetail.yourProposal.createdAt);
              final difference = now.difference(proposalTime);
              final inMinutes = difference.inMinutes;
              isOpenToSend = inMinutes >= 5;
            }
            // isOpenToSend = state.orderDetail.yourProposal.id == -1 ||
            //    (state.orderDetail.yourProposal.createdAt.isNotEmpty &&
            //        DateTime.parse(state.orderDetail.yourProposal.createdAt).difference(now).inMinutes >= 5);

            return Container(
              padding: EdgeInsets.fromLTRB(12, 12, 12, MediaQuery.paddingOf(context).bottom + 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                color: white,
                boxShadow: [
                  BoxShadow(
                    color: black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: isOpenToSend
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
                          child: Row(
                            children: [
                              Expanded(
                                child: CommonTextField(
                                  controller: _proposedPriceController,
                                  hint: 'Sizning taklifingiz',
                                  suffixIcon: Text(
                                    '\$',
                                    style: context.textTheme.bodyMedium!.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              CommonScaleAnimation(
                                onTap: () {
                                  context.read<OrdersBloc>().add(SendApplicationEvent(
                                      orderId: widget.orderId, proposedPrice: _proposedPriceController.text));
                                },
                                child: Container(
                                  height: 48,
                                  width: 48,
                                  margin: EdgeInsets.only(left: 12),
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: mainColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SvgPicture.asset(AppIcons.send),
                                ),
                              )
                            ],
                          ),
                        ),
                        AnimatedCrossFade(
                            firstChild: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CommonButton(
                                  margin: EdgeInsets.only(top: 12),
                                  onTap: () {
                                    context.read<OrdersBloc>().add(SendApplicationEvent(
                                        orderId: widget.orderId, proposedPrice: state.orderDetail.order.price));
                                  },
                                  text: 'Asl narxga rozi bo\'lish',
                                ),
                                SizedBox(height: 9),
                                Text(
                                  'Takliflarni har 5 daqiqada yuborish mumkin',
                                  style: context.textTheme.bodySmall!
                                      .copyWith(color: gray6, fontSize: 12, fontWeight: FontWeight.w400),
                                )
                              ],
                            ),
                            secondChild: SizedBox(),
                            crossFadeState: MediaQuery.viewInsetsOf(context).bottom == 0
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                            duration: Duration(milliseconds: 200))
                      ],
                    )
                  : Row(
                      children: [
                        Text(
                          'Keyingi taklif yuborish',
                          style: context.textTheme.bodyMedium!
                              .copyWith(color: gray4, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        Spacer(),
                        Image.asset(AppImages.hourglass, width: 23, height: 28),
                        SizedBox(width: 10),
                        Text(
                          timeLeft,
                          style: context.textTheme.bodyMedium!.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                        )
                      ],
                    ),
            );
          } else {
            return SizedBox.shrink();
          }
        },
      ),
    );
  }
}

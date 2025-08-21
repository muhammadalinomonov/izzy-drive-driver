import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:formz/formz.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/icons.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/common/presentation/widgets/common_scalel_animation.dart';
import 'package:mechanic/features/main/presentation/blocs/orders/orders_bloc.dart';
import 'package:mechanic/features/main/presentation/widgets/bottomsheets/finish_order_dialog.dart';
import 'package:mechanic/features/profile/presentation/blocs/profile_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderActionButtons extends StatelessWidget {
  const OrderActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state.status == 'onwork') {
          return BlocConsumer<OrdersBloc, OrdersState>(
            listenWhen: (previous, current) => previous.changeOrderStatus != current.changeOrderStatus,
            listener: (context, state) {
              if (state.changeOrderStatus.isSuccess) {
                context.read<OrdersBloc>().add(GetCurrentOrderEvent());
              }
            },
            builder: (context, state) {
              if (state.getCurrentOrderStatus.isSuccess) {
                final currentOrder = state.currentOrder;
                return Container(
                  padding:
                      EdgeInsets.only(right: 12, left: 12, top: 16, bottom: MediaQuery.paddingOf(context).bottom + 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    color: white,
                    boxShadow: [
                      BoxShadow(
                        color: black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: Offset(0, -4), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (currentOrder.status == 'accepted')
                        Text(
                          'Borishingiz kerek',
                          style: context.textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: gray5,
                          ),
                        ),
                      if (currentOrder.status == 'accepted')
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            final Uri uri = Uri.parse(
                                "geo:${currentOrder.currentAddress.latitude},${currentOrder.currentAddress.longitude}?q=${currentOrder.currentAddress.latitude},${currentOrder.currentAddress.longitude}");
                            if (await canLaunchUrl(uri)) {
                              launchUrl(uri);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Xarita ilovasi ochilmadi')),
                              );
                            }
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '3517 W. Gray St. Utica, Pennsylvania',
                                  style: context.textTheme.bodyMedium!.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                height: 30,
                                width: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: aliceBlue,
                                ),
                                child: SvgPicture.asset(AppIcons.location, color: mainColor),
                              )
                            ],
                          ),
                        ),
                      if (currentOrder.status == 'accepted') SizedBox(height: 16),
                      SwipeButton.expand(
                        duration: Duration(milliseconds: 1000),
                        activeThumbColor: currentOrder.status == 'accepted' ? black : mainColor,
                        activeTrackColor: currentOrder.status == 'accepted' ? gray2 : aliceBlue,
                        thumbPadding: EdgeInsets.all(3),
                        thumb: state.changeOrderStatus.isInProgress
                            ? Center(child: CircularProgressIndicator.adaptive())
                            : Icon(
                                Icons.chevron_right,
                                color: white,
                              ),
                        elevationThumb: 0,
                        elevationTrack: 0,
                        child: Shimmer.fromColors(
                          baseColor: prussianBlue,
                          highlightColor: perano,
                          child: Text(
                            nextStatus(currentOrder.status).text,
                            style: context.textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        onSwipe: () {
                          ///todo
                          final nextS = nextStatus(currentOrder.status).key;
                          context.read<OrdersBloc>().add(
                                ChangeOrderStatusEvent(
                                  orderId: currentOrder.id,
                                  status: nextStatus(currentOrder.status).key,
                                  onSuccess: () {
                                    if (nextS == 'mechanic_done') {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return FinishOrderDialog(orderId: currentOrder.id);
                                        },
                                      );
                                    }
                                  },
                                ),
                              );
                        },
                      ),
                      if (currentOrder.status == 'accepted' || currentOrder.status == 'arrived')
                        Align(
                          alignment: Alignment.center,
                          child: CommonScaleAnimation(
                            onTap: () {
                              showAdaptiveDialog(
                                context: context,
                                builder: (context) => AlertDialog.adaptive(
                                  title: Text('Buyurtmani bekor qilish'),
                                  content: Text('Rostan ham buyurtmani bekor qilmoqchimisiz?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text("Yo'q"),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        context
                                            .read<OrdersBloc>()
                                            .add(ChangeOrderStatusEvent(orderId: currentOrder.id, status: 'cancelled'));
                                      },
                                      child: Text(
                                        "Ha",
                                        style: context.textTheme.bodySmall!.copyWith(
                                          color: red,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Bekor qilish',
                                style: context.textTheme.bodySmall!.copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: gray4,
                                ),
                              ),
                            ),
                          ),
                        )
                    ],
                  ),
                );
              } else {
                return SizedBox();
              }
            },
          );
        } else {
          return SizedBox();
        }
      },
    );
  }

  ({String key, String text}) nextStatus(String currentStatus) {
    switch (currentStatus) {
      case 'accepted':
        return (key: 'arrived', text: 'Men yetib keldim');
      case 'arrived':
        return (key: 'in_progress', text: 'Men ishni boshladim');
      case 'in_progress':
        return (key: 'mechanic_done', text: 'Ishni yakunlash');
    }
    return (key: '', text: '');
  }
}

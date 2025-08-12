import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:formz/formz.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/icons.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/common/presentation/widgets/common_image.dart';
import 'package:mechanic/features/common/presentation/widgets/common_scalel_animation.dart';
import 'package:mechanic/features/main/presentation/blocs/orders/orders_bloc.dart';
import 'package:url_launcher/url_launcher_string.dart';

class CurrentActiveOrderWidget extends StatelessWidget {
  const CurrentActiveOrderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        if (state.getCurrentOrderStatus.isInProgress) {
          return Center(child: CircularProgressIndicator.adaptive());
        }
        if (state.getCurrentOrderStatus.isSuccess) {
          return Column(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buyurtma haqida ma’lumot',
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 18),
                    Row(
                      children: [
                        CommonImage(
                          imageUrl: state.currentOrder.driverAvatar,
                          width: 44,
                          height: 44,
                          borderRadius: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.currentOrder.driverName,
                                style: context.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Driver',
                                style: context.textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: gray4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CommonScaleAnimation(
                          onTap: () {
                            launchUrlString('tel:${state.currentOrder.driverPhone}');
                          },
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: aliceBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SvgPicture.asset(AppIcons.phone, width: 18, height: 18),
                          ),
                        )
                      ],
                    ),
                    Divider(
                      height: 25,
                      thickness: 1,
                      color: solitude,
                      indent: 0,
                      endIndent: 0,
                    ),
                    Text(
                      'Qayerga',
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: gray4,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      state.currentOrder.currentAddress.address,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    Divider(
                      height: 25,
                      thickness: 1,
                      color: solitude,
                      indent: 0,
                      endIndent: 0,
                    ),
                    Text(
                      'To’lov turi',
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: gray4,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        SvgPicture.asset(
                          AppIcons.apple,
                          width: 20,
                          height: 20,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Apple Pay',
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Spacer(),
                        Container(
                          height: 18,
                          width: 18,
                          decoration: BoxDecoration(
                            color: mainColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: SvgPicture.asset(AppIcons.check, width: 9, height: 9)),
                        ),
                        SizedBox(width: 6),
                        Text(
                          state.currentOrder.paymentStatus,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                decoration: BoxDecoration(
                  color: white,
                  borderRadius: BorderRadius.circular(12),

                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Qilishingiz kerek',
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 18),
                    Row(
                      children: [
                        SvgPicture.asset(
                          AppIcons.diogram,
                          width: 20,
                          height: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.currentOrder.status,
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          );
        } else {
          return Center(
            child: Text(
              'Hozirda faol buyurtma mavjud emas',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
      },
    );
  }
}

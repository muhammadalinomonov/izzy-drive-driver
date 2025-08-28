import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:formz/formz.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/icons.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/common/presentation/widgets/common_button.dart';
import 'package:mechanic/features/common/presentation/widgets/common_image.dart';
import 'package:mechanic/features/common/presentation/widgets/common_scalel_animation.dart';
import 'package:mechanic/features/main/presentation/blocs/orders/orders_bloc.dart';
import 'package:mechanic/features/main/presentation/widgets/bottomsheets/add_new_service_dialog.dart';
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
                      'Qilishingiz kerak',
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 18),
                    Row(
                      children: [
                        Text(
                          state.currentOrder.orderTitle,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: gray4,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 8),
                            color: solitude,
                            height: 1,
                          ),
                        ),
                        Text(
                          '\$${state.currentOrder.price}',
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ...List.generate(
                      state.currentOrder.suborders.length,
                      (index) {
                        final subOrder = state.currentOrder.suborders[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: index == state.currentOrder.suborders.length - 1 ? 0 : 12),
                          child: Row(
                            children: [
                              Text(
                                subOrder.title,
                                style: context.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  color: gray4,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 8),
                                  color: solitude,
                                  height: 1,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  final subOrderStatus = subOrder.status;
                                  if (subOrderStatus == 'accepted') {
                                    context.showPopUp(
                                        status: PopUpStatus.success, message: 'Bu buyurtma qabul qilingan.');
                                  } else if (subOrderStatus == 'cancelled') {
                                    context.showPopUp(status: PopUpStatus.error, message: 'Haydovchi bekor qildi.');
                                  } else {
                                    context.showPopUp(
                                        status: PopUpStatus.warning, message: 'Haydovchi tasdiqlashi kutilmoqda...');
                                  }
                                },
                                child: Container(
                                  margin: EdgeInsets.only(right: 8),
                                  height: 18,
                                  width: 18,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: subOrder.status == 'accepted'
                                        ? green
                                        : subOrder.status == 'cancelled'
                                            ? Colors.red
                                            : westSide,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '!',
                                    style: context.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: white,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                '\$${subOrder.price}',
                                style: context.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    if (state.currentOrder.status != 'accepted')
                      CommonButton(
                        margin: EdgeInsets.symmetric(vertical: 16),
                        border: Border.all(color: aliceBlue),
                        color: white,
                        onTap: () {
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (BuildContext context) {
                              return AddNewServiceDialog();
                            },
                          );
                        },
                        borderRadius: 12,
                        child: Text(
                          '+ Xizmat qo’shish',
                          style: context.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500, fontSize: 14, color: mainColor),
                        ),
                      ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: aliceBlue,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Umumiy summa',
                            style: context.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w400, fontSize: 14, color: matisse),
                          ),
                          Text(
                            '\$${state.currentOrder.totalPrice}',
                            style: context.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500, fontSize: 16, color: mainColor),
                          )
                        ],
                      ),
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:formz/formz.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/icons.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/core/utils/my_functions.dart';
import 'package:mechanic/features/common/presentation/widgets/common_button.dart';
import 'package:mechanic/features/common/presentation/widgets/common_image.dart';
import 'package:mechanic/features/main/presentation/widgets/order_information_widget.dart';
import 'package:mechanic/features/profile/presentation/blocs/history/orders_history_bloc.dart';

class OrderHistorySingleScreen extends StatefulWidget {
  const OrderHistorySingleScreen({super.key, required this.orderId, this.fromHistory = true});

  final int orderId;
  final bool fromHistory;

  @override
  State<OrderHistorySingleScreen> createState() => _OrderHistorySingleScreenState();
}

class _OrderHistorySingleScreenState extends State<OrderHistorySingleScreen> {
  @override
  void initState() {
    super.initState();

    context.read<OrdersHistoryBloc>().add(GetOrderHistoryDetailEvent(orderId: widget.orderId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: widget.fromHistory
          ? null
          : CommonButton(
              text: 'Asosiyga qaytish',
              margin: EdgeInsets.symmetric(horizontal: 12),
              onTap: () {
                Navigator.pop(context);
              },
            ),
      body: BlocBuilder<OrdersHistoryBloc, OrdersHistoryState>(
        builder: (context, state) {
          if (state.orderHistoryDetailStatus.isInProgress) {
            return Center(child: CircularProgressIndicator.adaptive());
          } else if (state.orderHistoryDetailStatus.isFailure) {
            return SizedBox();
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                if (widget.fromHistory)
                  Container(
                    width: context.sizeOf.width,
                    padding: EdgeInsets.only(top: context.padding.top + 12, right: 27, left: 12, bottom: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                      color: white,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: SvgPicture.asset(
                            AppIcons.arrowBack,
                            width: 24,
                            height: 24,
                          ),
                        ),
                        SizedBox(height: 22),
                        Text(
                          MyFunctions.formatDate(state.orderHistoryDetail.completedAt),
                          style: context.textTheme.bodyMedium!.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: context.sizeOf.width,
                    padding: EdgeInsets.only(top: context.padding.top + 18, right: 27, left: 27, bottom: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                      color: white,
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      SvgPicture.asset(
                        AppIcons.circularCheck,
                        width: 50,
                        height: 50,
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Muvaffaqiyatli yakunlandi!',
                        style: context.textTheme.bodyMedium!.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Lorem Ipsum is simply dummy text of the printing and typesetting industry',
                        style: context.textTheme.bodySmall!.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: gray4,
                        ),
                        textAlign: TextAlign.center,
                      )
                    ]),
                  ),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: white,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Haydovchi ma’lumotlari',
                        style: context.textTheme.bodyMedium!.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          CommonImage(
                            imageUrl: state.orderHistoryDetail.driverAvatar,
                            width: 44,
                            height: 44,
                            borderRadius: 22,
                            fit: BoxFit.cover,
                            errorImage: SvgPicture.asset(AppIcons.avatar),
                          ),
                          SizedBox(width: 12),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.orderHistoryDetail.driverName,
                                style: context.textTheme.bodyMedium!.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                state.orderHistoryDetail.driverPhone,
                                style: context.textTheme.bodySmall!.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: gray4,
                                ),
                              )
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),
                OrderInformationWidget(
                  createdAt: MyFunctions.formatDate(state.orderHistoryDetail.acceptedAt),
                  workDuration: state.orderHistoryDetail.workTime.formattedTime,
                  address: state.orderHistoryDetail.currentAddress.address,
                ),
                Container(
                  margin: EdgeInsets.only(top: 8),
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
                        'Xizmatlar',
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 18),
                      Row(
                        children: [
                          Text(
                            state.orderHistoryDetail.orderTitle,
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
                            '\$${state.orderHistoryDetail.price}',
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ...List.generate(
                        state.orderHistoryDetail.suborders.where((element) => element.status == 'accepted').length,
                        (index) {
                          final subOrder = state.orderHistoryDetail.suborders
                              .where((element) => element.status == 'accepted')
                              .toList()[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: index == 3 - 1 ? 0 : 12),
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
                      Container(
                        margin: EdgeInsets.only(top: 8),
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
                              '\$${state.orderHistoryDetail.totalPrice}',
                              style: context.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500, fontSize: 16, color: mainColor),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 88)
              ],
            ),
          );
        },
      ),
    );
  }
}

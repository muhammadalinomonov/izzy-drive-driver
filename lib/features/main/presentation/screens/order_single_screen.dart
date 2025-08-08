import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:formz/formz.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/icons.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/core/utils/my_functions.dart';
import 'package:mechanic/features/main/domain/entities/proposal_entity.dart';
import 'package:mechanic/features/main/presentation/blocs/orders/orders_bloc.dart';
import 'package:mechanic/features/main/presentation/widgets/offer_item.dart';
import 'package:mechanic/features/main/presentation/widgets/order_photos_widget.dart';
import 'package:mechanic/features/main/presentation/widgets/order_single_bottom.dart';
import 'package:mechanic/features/main/presentation/widgets/voice_message_item.dart';

class OrderSingleScreen extends StatefulWidget {
  const OrderSingleScreen({super.key, required this.orderId});

  final int orderId;

  @override
  State<OrderSingleScreen> createState() => _OrderSingleScreenState();
}

class _OrderSingleScreenState extends State<OrderSingleScreen> {
  final TextEditingController _proposedPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();

    context.read<OrdersBloc>().add(GetOrderDetailEvent(orderId: widget.orderId));
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismisser(
      child: Scaffold(
        backgroundColor: solitude,
        appBar: AppBar(
          backgroundColor: white,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: SvgPicture.asset(AppIcons.arrowBack),
          ),
          actions: [
            ///cancel self application
            // Container(
            //   alignment: Alignment.center,
            //   margin: EdgeInsets.only(right: 12),
            //   child: CommonScaleAnimation(
            //     onTap: () {},
            //     child: Container(
            //       height: 28,
            //       padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
            //       decoration: BoxDecoration(
            //         color: mainRed.withValues(alpha: .1),
            //         borderRadius: BorderRadius.circular(50),
            //       ),
            //       child: Text(
            //         'Bekor qilish',
            //         style: context.textTheme.bodyMedium!.copyWith(
            //           color: mainRed,
            //           fontSize: 14,
            //           fontWeight: FontWeight.w500,
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
        bottomNavigationBar: OrderSingleBottom(orderId: widget.orderId),
        body: BlocBuilder<OrdersBloc, OrdersState>(
          builder: (context, state) {
            if (state.orderDetailStatus.isInProgress) {
              return Center(child: CircularProgressIndicator.adaptive());
            } else if (state.orderDetailStatus.isFailure) {
              return Center(
                child: Text(
                  'Error occurred while fetching order details',
                  style: context.textTheme.bodyMedium!.copyWith(color: gray6),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  width: MediaQuery.sizeOf(context).width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                    color: white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.orderDetail.order.orderTitle,
                        style: context.textTheme.displayMedium,
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          SvgPicture.asset(AppIcons.currentLocation),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${state.orderDetail.order.distance} km',
                              style: context.textTheme.titleSmall!.copyWith(color: gray5),
                            ),
                          ),

                          ///Text(
                          //   '\$2400',
                          //   style: context.textTheme.bodySmall!.copyWith(
                          //     color: gray6,
                          //     decoration: TextDecoration.lineThrough,
                          //   ),
                          // ),
                          SizedBox(width: 6),
                          Text(
                            '\$3000',
                            style: context.textTheme.titleMedium,
                          ),
                          SizedBox(width: 6),
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: white,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(AppIcons.arrowUp),
                                SizedBox(width: 2),
                                Text(
                                  '25%',
                                  style: context.textTheme.bodySmall!
                                      .copyWith(color: green, fontSize: 10, fontWeight: FontWeight.w400),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: 12),
                      if (state.orderDetail.order.audio.isNotEmpty)
                        VoiceMessageItem(
                          audioUrl: state.orderDetail.order.audio,
                        ),
                      SizedBox(height: 12),
                      Text(
                        state.orderDetail.order.description,
                        style: context.textTheme.titleSmall!.copyWith(color: gray5, fontStyle: FontStyle.italic),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 12),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: grayLine,
                            )),
                        child: Row(
                          children: [
                            Text(
                              'Sizning takfilingiz',
                              style: context.textTheme.titleSmall!.copyWith(),
                            ),
                            Spacer(),
                            Text(
                              '\$2400',
                              style: context.textTheme.bodySmall!.copyWith(
                                color: gray6,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              '\$3000',
                              style: context.textTheme.titleMedium,
                            ),
                            SizedBox(width: 6),
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: white,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(AppIcons.arrowUp),
                                  SizedBox(width: 2),
                                  Text(
                                    '25%',
                                    style: context.textTheme.bodySmall!
                                        .copyWith(color: green, fontSize: 10, fontWeight: FontWeight.w400),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                if (state.orderDetail.order.images.isNotEmpty)
                  OrderPhotosWidget(
                    photos: state.orderDetail.order.images.map((e) => e.image).toList(),
                  ),
                if (state.orderDetail.proposals.isNotEmpty || state.orderDetail.yourProposal.id != -1)
                  Expanded(
                    ///todo
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 18.5, horizontal: 12),
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Takliflar',
                            style: context.textTheme.bodyMedium,
                          ),
                          SizedBox(height: 17.5),
                          Expanded(
                            child: ListView.separated(
                              itemBuilder: (context, index) {
                                late ProposalEntity proposal;
                                if (index == 0 && state.orderDetail.yourProposal.id != -1) {
                                  proposal = state.orderDetail.yourProposal;
                                } else if (index == 0 && state.orderDetail.yourProposal.id == -1) {
                                  proposal = state.orderDetail.proposals[index];
                                } else if (index > 0 && state.orderDetail.yourProposal.id != -1) {
                                  proposal = state.orderDetail.proposals[index - 1];
                                } else {
                                  proposal = state.orderDetail.proposals[index];
                                }
                                return OfferItem(
                                  image: proposal.proposedPrice,
                                  name: MyFunctions.formatTimeAgo(proposal.createdAt),
                                  time: MyFunctions.formatTimeAgo(proposal.createdAt),
                                  offer: '\$${MyFunctions.formatCost(proposal.price)}',
                                );
                              },
                              separatorBuilder: (context, index) => Divider(),
                              itemCount: state.orderDetail.proposals.length +
                                  (state.orderDetail.yourProposal.id != -1 ? 1 : 0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
              ],
            );
          },
        ),
      ),
    );
  }
}

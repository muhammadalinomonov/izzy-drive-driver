import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/icons.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/core/utils/my_functions.dart';

class OrderItem extends StatelessWidget {
  const OrderItem({
    super.key,
    this.isYouSentRequest = false,
    required this.title,
    required this.distance,
    required this.price,
    required this.createdAt,
    this.yourProposalPrice = '',
    this.yourProposalPricePercent = 0.0,
  });

  final bool isYouSentRequest;
  final String title;
  final String distance;
  final String price;
  final String createdAt;
  final String yourProposalPrice;
  final double yourProposalPricePercent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12).copyWith(bottom: 14),
      decoration: BoxDecoration(
        boxShadow: isYouSentRequest
            ? [
                BoxShadow(
                  color: black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: Offset(0, 0),
                ),
              ]
            : null,
        borderRadius: BorderRadius.circular(16),
        color: isYouSentRequest ? white : solitude,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                MyFunctions.formatTimeAgo(createdAt),
                style: context.textTheme.bodySmall!.copyWith(color: gray5),
              ),
              if (isYouSentRequest)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: green.withValues(alpha: 0.08),
                  ),
                  child: Text(
                    'Siz taklif berdingiz',
                    style: context.textTheme.bodySmall!.copyWith(
                      color: green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
            ],
          ),
          SizedBox(height: 6),
          Text(
            title,
            style: context.textTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 6),
          Row(
            children: [
              SvgPicture.asset(AppIcons.currentLocation),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$distance km uzoqlikda',
                  style: context.textTheme.titleSmall!.copyWith(color: gray5),
                ),
              ),
              // Text(
              //   '\$2400',
              //   style: context.textTheme.bodySmall!.copyWith(
              //     color: gray6,
              //     decoration: TextDecoration.lineThrough,
              //   ),
              // ),
              SizedBox(width: 6),
              Text(
                '\$$price',
                style: context.textTheme.titleMedium,
              ),
              SizedBox(width: 6),
              // Container(
              //   padding: EdgeInsets.symmetric(vertical: 3, horizontal: 4),
              //   decoration: BoxDecoration(
              //     borderRadius: BorderRadius.circular(50),
              //     color: white,
              //   ),
              //   child: Row(
              //     mainAxisSize: MainAxisSize.min,
              //     children: [
              //       SvgPicture.asset(AppIcons.arrowUp),
              //       SizedBox(width: 2),
              //       Text(
              //         '25%',
              //         style: context.textTheme.bodySmall!
              //             .copyWith(color: green, fontSize: 10, fontWeight: FontWeight.w400),
              //       ),
              //     ],
              //   ),
              // )
            ],
          ),
          if (isYouSentRequest) Divider(height: 25, color: solitude, thickness: 1),
          if (isYouSentRequest)
            Row(
              children: [
                Text(
                  'Sizning taklifingiz',
                  style: context.textTheme.bodySmall!.copyWith(color: gray6),
                ),
                Spacer(),
                Text(
                  '\$$yourProposalPrice',
                  style: context.textTheme.titleMedium,
                ),
                Container(
                  margin: EdgeInsets.only(left: 8),
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: red.withValues(alpha: .1),
                  ),
                  child: Text(
                    '${yourProposalPricePercent.toStringAsFixed(0)}%',
                    style: context.textTheme.bodySmall!.copyWith(
                      color: red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
                // Column(
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //
                //     SizedBox(height: 2),
                //     Text(
                //       '3:00',
                //       style: context.textTheme.titleMedium,
                //     ),
                //   ],
                // ),
                // Column(
                //   crossAxisAlignment: CrossAxisAlignment.end,
                //   children: [
                //     Text(
                //       'Keyingi taklif yuborish',
                //       style: context.textTheme.bodySmall!.copyWith(color: gray6),
                //     ),
                //     SizedBox(height: 2),
                //     Row(
                //       mainAxisAlignment: MainAxisAlignment.end,
                //       mainAxisSize: MainAxisSize.min,
                //       children: [
                //         Text(
                //           '3:00',
                //           style: context.textTheme.titleMedium,
                //         ),
                //         SizedBox(width: 4),
                //         Container(
                //           padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                //           decoration: BoxDecoration(
                //             borderRadius: BorderRadius.circular(50),
                //             color: green.withValues(alpha: 0.08),
                //           ),
                //           child: Text(
                //             '8%',
                //             style: context.textTheme.bodySmall!.copyWith(
                //               color: green,
                //               fontSize: 12,
                //               fontWeight: FontWeight.w500,
                //             ),
                //           ),
                //         )
                //       ],
                //     ),
                //   ],
                // ),
              ],
            )
        ],
      ),
    );
  }
}

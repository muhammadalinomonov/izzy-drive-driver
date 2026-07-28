import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';

class SubOrderItem extends StatelessWidget {
  const SubOrderItem({
    super.key,
    required this.name,
    required this.price,
    required this.status,
    required this.onAction,
  });

  final String name;
  final String price;
  final String status;
  final Function(bool isAccepted) onAction;

  @override
  Widget build(BuildContext context) {
    if (status == 'pending') {
      return Container(
        margin: EdgeInsets.only(top: 8),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppColor.black.withValues(alpha: 0.1), blurRadius: 12, offset: Offset(0, 0))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$name ',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(fontSize: 13, fontWeight: FontWeight.w400, color: AppColor.grey),
                ),
                Expanded(child: Divider(color: AppColor.lightBlue)),
                Text(
                  ' $price',
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Reject (chap) | Accept (o'ng) — SubOrderProposalSheet bilan
            // bir xil tartib va matn, foydalanuvchi qaerdan ko'rsa ham bir
            // xil tugmalarni kutadi.
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      onAction.call(false);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: AppColor.lightBlue, borderRadius: BorderRadius.circular(50)),
                      child: Text(
                        'Reject',
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge!.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      onAction.call(true);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: AppColor.kPrimaryColor, borderRadius: BorderRadius.circular(50)),
                      child: Text(
                        'Accept',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColor.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '$name ',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge!.copyWith(fontSize: 13, fontWeight: FontWeight.w400, color: AppColor.grey),
          ),
          Expanded(child: Divider(color: AppColor.lightBlue)),
          if (status == 'cancelled')
            Container(
              decoration: BoxDecoration(
                color: AppColor.red.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(50),
              ),
              alignment: Alignment.center,
              height: 16,
              width: 16,
              child: SvgPicture.asset(AppIcons.x, width: 8, height: 8),
            ),
          Text(
            ' $price',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_images.dart';
import 'package:taxi_app/src/core/enums/order_enums.dart';

class ActiveOrderWidget extends StatelessWidget {
  const ActiveOrderWidget({super.key, required this.orderId, required this.status});

  final int orderId;
  final OrderStatus status;

  Color get _accentColor {
    if (status.isPending || status.isMechanicSelected) return const Color(0xFFFFA800);
    if (status.isCanceled) return const Color(0xFFE53935);
    if (status.isMechanicDone) return const Color(0xFF22B07D);
    return AppColor.blueMain;
  }

  String get _statusLabel {
    if (status.isPending) return 'Pending';
    if (status.isMechanicSelected) return 'Searching';
    if (status.isAccepted) return 'On the way';
    if (status.isArrived) return 'Arrived';
    if (status.isInProgress) return 'In progress';
    if (status.isMechanicDone) return 'Completed';
    if (status.isCanceled) return 'Canceled';
    return 'Active';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: AppColor.grey2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image.asset(AppImages.key, width: 32, height: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Active order'.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 0.6,
                        color: AppColor.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        _statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'No. $orderId',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status.orderDescription,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColor.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColor.lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: accent),
          ),
        ],
      ),
    );
  }
}

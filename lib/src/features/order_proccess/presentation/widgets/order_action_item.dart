import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';

class OrderActionItem extends StatelessWidget {
  const OrderActionItem({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.badgeCount,
  });

  final String icon;
  final String text;
  final VoidCallback onTap;

  /// Yuqori-o'ng burchakda orange badge ko'rsatadi. `null` yoki `<= 0` - badge yo'q.
  /// Qiymat berilgan bo'lsa: 1 → faqat aylana, 2+ → raqam.
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final count = badgeCount ?? 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: 50,
            width: 50,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColor.lightBlue),
                  alignment: Alignment.center,
                  child: Center(child: SvgPicture.asset(icon, width: 19, height: 19)),
                ),
                if (count > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8A00),
                        shape: count > 1 ? BoxShape.rectangle : BoxShape.circle,
                        borderRadius: count > 1 ? BorderRadius.circular(50) : null,
                        border: Border.all(color: AppColor.white, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: count > 1
                          ? Text(
                              count > 9 ? '9+' : '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                              ),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(text, style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w500, fontSize: 12)),
      ],
    );
  }
}

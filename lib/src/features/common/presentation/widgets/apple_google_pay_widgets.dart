// Preserved Apple Pay / Google Pay UI — currently replaced by cash payment. Restore if those payment methods are reintroduced.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';

class PaymentOptionsSection extends StatefulWidget {
  const PaymentOptionsSection({super.key});

  @override
  State<PaymentOptionsSection> createState() => _PaymentOptionsSectionState();
}

class _PaymentOptionsSectionState extends State<PaymentOptionsSection> {
  bool isApple = Platform.isIOS;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PaymentOptionTile(
          icon: AppIcons.apple,
          label: 'Apple Pay',
          selected: isApple,
          onTap: () => setState(() => isApple = true),
        ),
        Divider(
          endIndent: 10,
          indent: 10,
          color: AppColor.lightGrey,
          height: 0.1,
        ),
        PaymentOptionTile(
          icon: AppIcons.google,
          label: 'Google Pay',
          selected: !isApple,
          onTap: () => setState(() => isApple = false),
        ),
      ],
    );
  }
}

class PaymentOptionTile extends StatelessWidget {
  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const PaymentOptionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return ListTile(
          leading: SvgPicture.asset(icon),
          title: Text(label),
          trailing: Transform.scale(
            scale: 1.3,
            child: Checkbox(
              side: const BorderSide(width: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              value: selected,
              onChanged: (bool? value) {},
            ),
          ),
          onTap: onTap,
        );
      },
    );
  }
}

/// Informational Apple Pay row used in order details (no toggle).
class ApplePayInfoRow extends StatelessWidget {
  const ApplePayInfoRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment type',
          style: context.textTheme.bodySmall!.copyWith(
            fontSize: 12,
            color: AppColor.grey2,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            SvgPicture.asset(AppIcons.apple, width: 20),
            const SizedBox(width: 4),
            Text(
              'Apple Pay',
              style: context.textTheme.bodySmall!.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            // SvgPicture.asset(AppIcons.circularCheck, width: 20, height: 20),
            const SizedBox(width: 4),
            // Text(
            //   'To'landi',
            //   style: context.textTheme.bodySmall!.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
            // ),
          ],
        ),
      ],
    );
  }
}

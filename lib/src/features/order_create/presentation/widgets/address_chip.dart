import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';

/// Pill-shaped address summary used in the order-create header
/// (Figma `1817:25330`).
class AddressChip extends StatelessWidget {
  const AddressChip({super.key, required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    final text = address.isEmpty ? 'No location selected' : address;
    final shown = text.length > 35 ? '${text.substring(0, 35)}…' : text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F6),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(AppIcons.location, width: 16, height: 16),
          const SizedBox(width: 6),
          Text(
            shown,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.3,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

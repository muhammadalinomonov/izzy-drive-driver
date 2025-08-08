import 'package:flutter/material.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/common/presentation/widgets/common_image.dart';

class OfferItem extends StatelessWidget {
  const OfferItem({
    super.key,
    required this.image,
    required this.name,
    required this.time,
    required this.offer,
  });

  final String image;
  final String name;
  final String time;
  final String offer;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CommonImage(
          imageUrl:
              'https://png.pngtree.com/png-clipart/20231019/original/pngtree-user-profile-avatar-png-image_13369990.png',
          width: 38,
          height: 38,
          fit: BoxFit.cover,
          borderRadius: 19,
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'John Doe',
              style: context.textTheme.bodyMedium!.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text(
              'Offer: \$150',
              style: context.textTheme.bodySmall!.copyWith(color: Colors.grey[600]),
            ),
          ],
        )
      ],
    );
  }
}

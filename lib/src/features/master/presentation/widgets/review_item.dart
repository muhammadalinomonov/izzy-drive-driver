import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';
import 'package:taxi_app/src/core/utils/my_functions.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_image.dart';

class ReviewItem extends StatelessWidget {
  const ReviewItem({
    super.key,
    required this.avatar,
    required this.name,
    required this.date,
    required this.review,
    required this.rating,
  });

  final String avatar;
  final String name;
  final String date;
  final String review;
  final int rating;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CommonNetworkImage(imageUrl: avatar, width: 38, height: 38, radius: 19),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
              ],
            ),
          ],
        ),
        SizedBox(height: 12),
        Text(review, style: context.textTheme.bodyLarge!.copyWith(fontSize: 12, fontWeight: FontWeight.w400)),
        SizedBox(height: 12),
        Text(
          MyFunctions.formatDateTime(date),
          style: context.textTheme.bodyLarge!.copyWith(fontSize: 12, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}

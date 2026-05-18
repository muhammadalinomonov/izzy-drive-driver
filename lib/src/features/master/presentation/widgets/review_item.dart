import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
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

  /// 0..5 oralig'idagi yulduz soni.
  final int rating;

  @override
  Widget build(BuildContext context) {
    final clampedRating = rating.clamp(0, 5);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AvatarImage(imageUrl: avatar, name: name, size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      for (var i = 0; i < 5; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Icon(
                            i < clampedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 14,
                            color: i < clampedRating
                                ? const Color(0xFFFFB800)
                                : AppColor.grey2,
                          ),
                        ),
                      const SizedBox(width: 4),
                      Text(
                        '$clampedRating',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          review,
          style: context.textTheme.bodyLarge!.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          MyFunctions.relativeDate(date),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColor.grey,
          ),
        ),
      ],
    );
  }
}

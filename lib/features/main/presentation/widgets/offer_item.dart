import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mechanic/assets/colors/colors.dart';
import 'package:mechanic/assets/constants/icons.dart';
import 'package:mechanic/core/utils/context_extensions.dart';
import 'package:mechanic/features/common/presentation/widgets/common_image.dart';

class OfferItem extends StatelessWidget {
  const OfferItem({
    super.key,
    required this.image,
    required this.name,
    required this.time,
    required this.offer,
    required this.percent,
    required this.isYou,
  });

  final String image;
  final String name;
  final String time;
  final String offer;
  final String percent;
  final bool isYou;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CommonImage(
          imageUrl: image,
          width: 38,
          height: 38,
          fit: BoxFit.cover,
          errorImage: SvgPicture.asset(
            AppIcons.avatar,
            width: 38,
            height: 38,
          ),
          borderRadius: 19,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: context.textTheme.bodyMedium!.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if(isYou)Container(
                    margin: EdgeInsets.only(left: 8),
                    padding: EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                    decoration: BoxDecoration(
                      color: mainColor,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'You',
                      style: context.textTheme.bodySmall!.copyWith(color: white),
                    ),
                  )
                ],
              ),
              SizedBox(height: 4),
              Text(
                time,
                style: context.textTheme.bodySmall!.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Text(
          offer,
          style: context.textTheme.bodyMedium!.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), color: red.withValues(alpha: .1)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(AppIcons.arrowUp),
              Text(percent, style: context.textTheme.bodySmall!.copyWith(color: red, fontSize: 10))
            ],
          ),
        )
      ],
    );
  }
}

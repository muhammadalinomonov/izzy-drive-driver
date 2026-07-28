import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/features/trips/data/model/place_model.dart';

/// A row in the sheet's lower list - used for both recent history and live
/// search suggestions, which differ only by leading icon.
class PlaceListTile extends StatelessWidget {
  const PlaceListTile({
    super.key,
    required this.place,
    required this.onTap,
    this.isHistory = false,
    this.trailingText,
  });

  final PlaceModel place;
  final VoidCallback onTap;
  final bool isHistory;

  /// Estimated travel time ("22 min" in docs/ui/3.png). Rendered only when
  /// supplied - neither the places endpoint nor the local history carries a
  /// duration, so today this is always null.
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    final subtitle = place.subtitle;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Grey bullet from the design, used for both search suggestions
            // and recent history - 3.png renders every row of the list the
            // same way. Authored grey, so no tint.
            SvgPicture.asset(AppIcons.tripDot, width: 14, height: 14),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    place.name.isNotEmpty ? place.name : place.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColor.black,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: AppColor.grey),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingText != null) ...[
              const SizedBox(width: 10),
              Text(
                trailingText!,
                style: TextStyle(fontSize: 13, color: AppColor.darkGrey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';

/// Read-only entry point to the trip-planning flow, shown above the trip
/// history on the Trips tab. It never accepts input itself - tapping it opens
/// [TripMapPage], where the real origin/destination fields live.
class TripSearchBar extends StatelessWidget {
  const TripSearchBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColor.lightBlue,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Icon(Icons.search, size: 20, color: AppColor.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'tripMap.searchBarHint'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, color: AppColor.lightGreyBlue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

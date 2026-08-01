import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/core/constants/color/app_icons.dart';

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
          height: 52,
          padding: const EdgeInsets.only(left: 8, right: 16),
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColor.grey2),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 2),
                blurRadius: 10,
                color: Colors.black.withAlpha(15),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColor.kPrimary2Color,
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  AppIcons.search,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    AppColor.kPrimaryColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'tripMap.searchBarHint'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColor.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

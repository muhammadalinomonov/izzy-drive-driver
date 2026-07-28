import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/features/trips/presentation/bloc/trip_map/trip_map_bloc.dart';

/// The two stacked search fields from `docs/ui/3.png`: "Your Location" (pin)
/// over "Delivery Adress" (checkered flag), inside one rounded grey card.
class LocationFieldsCard extends StatelessWidget {
  const LocationFieldsCard({
    super.key,
    required this.originController,
    required this.destinationController,
    required this.originFocus,
    required this.destinationFocus,
    required this.activeField,
    required this.originLoading,
    required this.onChanged,
    required this.onFocused,
    this.onMapTap,
  });

  final TextEditingController originController;
  final TextEditingController destinationController;
  final FocusNode originFocus;
  final FocusNode destinationFocus;
  final TripMapField activeField;
  final bool originLoading;
  final ValueChanged<String> onChanged;
  final ValueChanged<TripMapField> onFocused;
  final VoidCallback? onMapTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.lightBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        children: [
          _Field(
            icon: _FieldIcon(
              asset: AppIcons.tripOrigin,
              active: activeField == TripMapField.origin,
            ),
            label: 'tripMap.yourLocation'.tr(),
            hint: 'tripMap.originHint'.tr(),
            controller: originController,
            focusNode: originFocus,
            isActive: activeField == TripMapField.origin,
            loading: originLoading,
            onChanged: onChanged,
            onTap: () => onFocused(TripMapField.origin),
          ),
          Divider(color: AppColor.grey2, height: 1),
          _Field(
            icon: _FieldIcon(
              asset: AppIcons.tripDestination,
              active: activeField == TripMapField.destination,
              size: 20,
            ),
            label: 'tripMap.destination'.tr(),
            hint: 'tripMap.destinationHint'.tr(),
            controller: destinationController,
            focusNode: destinationFocus,
            isActive: activeField == TripMapField.destination,
            loading: false,
            onChanged: onChanged,
            onTap: () => onFocused(TripMapField.destination),
            trailing: onMapTap == null ? null : _MapChip(onTap: onMapTap!),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.icon,
    required this.label,
    required this.hint,
    required this.controller,
    required this.focusNode,
    required this.isActive,
    required this.loading,
    required this.onChanged,
    required this.onTap,
    this.trailing,
  });

  final Widget icon;
  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isActive;
  final bool loading;
  final ValueChanged<String> onChanged;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 30, child: Center(child: icon)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: AppColor.grey),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onTap: onTap,
                  onChanged: onChanged,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColor.black,
                  ),
                  cursorColor: AppColor.kPrimaryColor,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: AppColor.lightGreyBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (trailing != null)
            Padding(padding: const EdgeInsets.only(left: 8), child: trailing!),
        ],
      ),
    );
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColor.grey2,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'tripMap.map'.tr(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColor.grey,
          ),
        ),
      ),
    );
  }
}

/// Field icon from `assets/icons`.
///
/// Both SVGs are authored as a single grey stroke (#93989B), so they are
/// tinted rather than used as-is: grey while idle, primary blue while that
/// field is the active search target - which is how 3.png shows the focused
/// destination flag.
class _FieldIcon extends StatelessWidget {
  const _FieldIcon({required this.asset, required this.active, this.size = 20});

  final String asset;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        active ? AppColor.kPrimaryColor : AppColor.darkGrey,
        BlendMode.srcIn,
      ),
    );
  }
}

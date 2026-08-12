import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/core/constants/color/app_icons.dart';
import 'package:taxi_app/core/utils/unit_format.dart';
import 'package:taxi_app/features/trips/data/model/fuel_station_model.dart';
import 'package:taxi_app/features/trips/data/model/trip_model.dart';

/// What kind of thing a marker represents. Adding a new marker type means
/// adding a case here and a matching factory on [MarkerInfo] - the sheet
/// itself does not change.
enum MarkerKind { fuelStation, toll }

/// Title and row-value text colour, traced from `docs/ui/5-2.svg`'s text
/// paths (`fill="#01060F"`) - a hair off pure black, not [AppColor.black].
/// Struck-through prices and button labels use their own colours already and
/// are unaffected.
const Color _kTextDark = Color(0xFF01060F);

/// Screen-agnostic description of a tapped map marker.
///
/// Both fuel stations and toll gantries collapse into this one shape so a
/// single sheet can render either, per the task's "do not duplicate the
/// implementation". Fields the source model has no answer for are simply left
/// null and their row is omitted.
class MarkerInfo {
  final MarkerKind kind;

  /// Small grey label above the title, e.g. "Fuel Station Name".
  final String typeLabel;
  final String title;
  final String? address;

  /// Current price, already formatted for display.
  final String? price;

  /// Struck-through original price, shown beside [price] when the station is
  /// discounted. Null when there is nothing to compare against.
  final String? priceStruckThrough;

  /// Qualifier appended to the price row's label, e.g. "Tax excluded". Fuel
  /// prices are meaningless without it.
  final String? priceNote;

  final String? distance;
  final TripCoordinate coordinate;

  /// Optional photo. Falls back to a tinted icon tile when absent, which is
  /// the common case until the API returns imagery.
  final String? imageUrl;

  const MarkerInfo({
    required this.kind,
    required this.typeLabel,
    required this.title,
    required this.coordinate,
    this.address,
    this.price,
    this.priceStruckThrough,
    this.priceNote,
    this.distance,
    this.imageUrl,
  });

  factory MarkerInfo.fromFuelStation(FuelStationModel station) {
    final primary = station.primaryPrice;
    // Both tax variants published: the design's "$54.54 $54.54" pair, with the
    // contracted (tax-excluded) rate leading and the other struck through.
    final secondary = station.secondaryPrice;
    return MarkerInfo(
      kind: MarkerKind.fuelStation,
      typeLabel: 'markerSheet.fuelStationName'.tr(),
      title: station.title,
      address: station.address.isEmpty ? null : station.address,
      // Per docs §7.2 a station with no published price still belongs on the
      // map, labelled rather than hidden.
      price: primary?.formatted ?? 'markerSheet.priceUnavailable'.tr(),
      priceStruckThrough: secondary?.formatted,
      // The price is contracted, not the pump price, and the tax variant has
      // to be stated explicitly - the backend neither adds nor removes tax.
      priceNote: primary == null
          ? null
          : (primary.taxIncluded
              ? 'markerSheet.taxIncluded'.tr()
              : 'markerSheet.taxExcluded'.tr()),
      distance: station.distanceMeters == null
          ? null
          : formatMiles(station.distanceMeters!),
      coordinate: station.coordinate,
    );
  }

  factory MarkerInfo.fromTollMarker(
    TripTollMarker marker, {
    int? distanceMeters,
  }) {
    return MarkerInfo(
      kind: MarkerKind.toll,
      typeLabel: 'markerSheet.tollName'.tr(),
      title: marker.name.isEmpty
          ? 'markerSheet.tollPoint'.tr(args: ['${marker.sequence}'])
          : marker.name,
      price: marker.amount?.formatted,
      distance: distanceMeters == null ? null : formatMiles(distanceMeters),
      coordinate: marker.coordinate,
    );
  }

}

/// What the driver chose in the sheet's action area.
enum MarkerSheetAction {
  /// Route to this marker and drive it yourself - the regular users' single
  /// "To go there" button and the premium layout's "Drive".
  drive,

  /// Premium only: hand the stop to support instead of driving straight there.
  requestRefueling,
}

/// Opens the marker information sheet.
///
/// [showActionButton] is the single switch between the two behaviours the task
/// describes: `true` on the trip planner, where picking a marker sets it as
/// the destination, and `false` on Route Overview and Driving Mode, which are
/// informational and must not alter a route in progress.
///
/// [premium] selects the two-button premium layout (`docs/ui/5-2.svg`) over the
/// standard single-button one (`docs/ui/5-1.png`). It only applies to fuel
/// stations, and only alongside [showActionButton].
///
/// Returns the action the driver picked, or null if they dismissed the sheet.
Future<MarkerSheetAction?> showMarkerInfoSheet(
  BuildContext context, {
  required MarkerInfo info,
  bool showActionButton = false,
  bool premium = false,
  VoidCallback? onDismissed,
}) {
  return showModalBottomSheet<MarkerSheetAction>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    // Tapping outside dismisses, per the brief.
    isDismissible: true,
    builder: (_) => MarkerInfoSheet(
      info: info,
      showActionButton: showActionButton,
      premium: premium,
    ),
  ).whenComplete(() => onDismissed?.call());
}

/// Marker detail sheet, built to `docs/ui/5-1.png` (standard) and
/// `docs/ui/5-2.svg` (premium).
class MarkerInfoSheet extends StatelessWidget {
  const MarkerInfoSheet({
    super.key,
    required this.info,
    this.showActionButton = false,
    this.premium = false,
  });

  final MarkerInfo info;
  final bool showActionButton;

  /// Premium entitlement. Drives the two-button action row for fuel stations;
  /// ignored for toll markers, which have no premium variant.
  final bool premium;

  /// Refuelling is a fuel-station action, so the premium layout is only used
  /// where it means something.
  bool get _premiumFuel =>
      premium && showActionButton && info.kind == MarkerKind.fuelStation;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        // Radius 18: exact, back-computed from the sheet's own rounded-rect
        // corner curve in docs/ui/5-2.svg (kappa * r = 9.941 => r = 18).
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColor.grey2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: _Header(info: info),
            ),
            const SizedBox(height: 6),
            if (info.address != null)
              _InfoRow(
                icon: AppIcons.tripOrigin,
                label: 'markerSheet.location'.tr(),
                value: info.address!,
              ),
            if (info.price != null)
              _InfoRow(
                // Traced from docs/ui/5-2.svg: the row labelled "Price" is
                // drawn with the pin+dashes glyph (ic_mile_outline.svg's own
                // artwork), not a wallet/currency icon - the source design
                // pairs the two icons opposite to what their filenames
                // suggest, and this reproduces it exactly rather than what
                // seems intuitive.
                icon: AppIcons.markerMile,
                label: info.priceNote == null
                    ? 'markerSheet.price'.tr()
                    : '${'markerSheet.price'.tr()} · ${info.priceNote}',
                value: info.price!,
                struckThrough: info.priceStruckThrough,
              ),
            if (info.distance != null)
              _InfoRow(
                // Same swap as above: the "Mile" row uses the $-in-circle
                // glyph (ic_price.svg's artwork) in the source design.
                icon: AppIcons.price,
                label: 'markerSheet.mile'.tr(),
                value: info.distance!,
                showDivider: false,
              ),
            if (showActionButton) ...[
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: _premiumFuel
                    ? _PremiumActions(
                        onRequestRefueling: () => Navigator.of(context)
                            .pop(MarkerSheetAction.requestRefueling),
                        onDrive: () =>
                            Navigator.of(context).pop(MarkerSheetAction.drive),
                      )
                    : _PrimaryAction(
                        label: 'markerSheet.toGoThere'.tr(),
                        onPressed: () =>
                            Navigator.of(context).pop(MarkerSheetAction.drive),
                      ),
              ),
            ] else
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Standard single action, full width: "To go there" (`docs/ui/5-1.png`).
class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      // 44/22: exact match to docs/ui/5-2.svg's button rects (height 44,
      // rx 22 - a full pill, not an approximation of one).
      height: 44,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColor.kPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.navigation_rounded, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// Premium action pair (`docs/ui/5-2.svg`): a filled "Request Refueling"
/// alongside a tonal "Drive". Refuelling leads because it is the premium
/// feature; Drive keeps the arrow so it stays recognisable as the same action
/// standard users get.
class _PremiumActions extends StatelessWidget {
  const _PremiumActions({
    required this.onRequestRefueling,
    required this.onDrive,
  });

  final VoidCallback onRequestRefueling;
  final VoidCallback onDrive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // flex 4:3 matches docs/ui/5-2.svg's button widths (198:141 ~= 1.404)
        // closer than an even 3:2 split would.
        Expanded(
          flex: 4,
          child: SizedBox(
            height: 44,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColor.kPrimaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              onPressed: onRequestRefueling,
              child: Text(
                'markerSheet.requestRefueling'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 44,
            child: FilledButton(
              style: FilledButton.styleFrom(
                // The design's pale grey pill; same token the sheet already
                // uses for the image fallback tile.
                backgroundColor: AppColor.lightBlue,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              onPressed: onDrive,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'markerSheet.drive'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColor.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.navigation_rounded,
                    size: 18,
                    color: AppColor.kPrimaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.info});

  final MarkerInfo info;

  @override
  Widget build(BuildContext context) {
    final image = info.imageUrl;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          // 74x60: docs/ui/5-2.svg's header image is a non-square rectangle,
          // not the 64x64 square this used to be.
          child: SizedBox(
            width: 74,
            height: 60,
            child: image != null && image.isNotEmpty
                ? Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _ImageFallback(info: info),
                  )
                : _ImageFallback(info: info),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                info.typeLabel,
                style: TextStyle(fontSize: 12, color: AppColor.grey),
              ),
              const SizedBox(height: 3),
              Text(
                info.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _kTextDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tinted tile shown when the marker has no photo, keyed to the marker type so
/// a toll point and a fuel station stay visually distinct.
class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.info});

  final MarkerInfo info;

  @override
  Widget build(BuildContext context) {
    final isFuel = info.kind == MarkerKind.fuelStation;
    return Container(
      color: AppColor.lightBlue,
      child: Center(
        child: SvgPicture.asset(
          isFuel ? AppIcons.gasStation : AppIcons.routeToll,
          width: 28,
          height: 28,
          colorFilter: ColorFilter.mode(
            AppColor.kPrimaryColor,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.struckThrough,
    this.showDivider = true,
  });

  final String icon;
  final String label;
  final String value;
  final String? struckThrough;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final original = struckThrough;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // No border/background chip: docs/ui/5-2.svg draws each row
              // icon bare. The SizedBox just reserves a consistent slot for
              // alignment across rows: the icons' own artwork already ships
              // with the design's exact #93989B stroke, so no colorFilter
              // tint is applied either - tinting it would only risk drifting
              // from that colour again.
              SizedBox(
                width: 34,
                height: 34,
                child: Center(
                  child: SvgPicture.asset(icon, width: 20, height: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 12, color: AppColor.grey),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            value,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _kTextDark,
                            ),
                          ),
                        ),
                        if (original != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            original,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColor.grey,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppColor.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            // docs/ui/5-2.svg's row dividers are #EFF3F6, a shade lighter
            // than AppColor.grey2 (#E3E8EB) which was used here before.
            child: Divider(height: 1, color: AppColor.lightBlue),
          ),
      ],
    );
  }
}

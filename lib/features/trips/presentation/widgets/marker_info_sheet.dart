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
    this.distance,
    this.imageUrl,
  });

  factory MarkerInfo.fromFuelStation(FuelStationModel station) {
    // A range renders as the low price with the high one struck through,
    // matching the design's "$54.54 $54.54" pair.
    final hasRange = station.priceMinMinor != null &&
        station.priceMaxMinor != null &&
        station.priceMinMinor != station.priceMaxMinor;
    return MarkerInfo(
      kind: MarkerKind.fuelStation,
      typeLabel: 'markerSheet.fuelStationName'.tr(),
      title: station.name.isEmpty ? station.brand : station.name,
      address: station.address.isEmpty ? null : station.address,
      price: station.priceLabel.isEmpty
          ? null
          : (hasRange
              ? _money(station.priceMinMinor!, station.currency)
              : station.priceLabel),
      priceStruckThrough:
          hasRange ? _money(station.priceMaxMinor!, station.currency) : null,
      distance: formatMiles(station.distanceMeters),
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

  static String _money(int minor, String currency) {
    final value = (minor / 100).toStringAsFixed(2);
    return switch (currency.toUpperCase()) {
      'USD' => '\$$value',
      'EUR' => '€$value',
      final other => '$value $other',
    };
  }
}

/// Opens the marker information sheet.
///
/// [showActionButton] is the single switch between the two behaviours the task
/// describes: `true` on the trip planner, where picking a marker sets it as
/// the destination, and `false` on Route Overview and Driving Mode, which are
/// informational and must not alter a route in progress.
///
/// Returns `true` when the driver pressed "To go there".
Future<bool?> showMarkerInfoSheet(
  BuildContext context, {
  required MarkerInfo info,
  bool showActionButton = false,
  VoidCallback? onDismissed,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    // Tapping outside dismisses, per the brief.
    isDismissible: true,
    builder: (_) => MarkerInfoSheet(
      info: info,
      showActionButton: showActionButton,
    ),
  ).whenComplete(() => onDismissed?.call());
}

/// Marker detail sheet, built to `docs/ui/5-1.png`.
class MarkerInfoSheet extends StatelessWidget {
  const MarkerInfoSheet({
    super.key,
    required this.info,
    this.showActionButton = false,
  });

  final MarkerInfo info;
  final bool showActionButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColor.grey2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
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
                icon: AppIcons.price,
                label: 'markerSheet.price'.tr(),
                value: info.price!,
                struckThrough: info.priceStruckThrough,
              ),
            if (info.distance != null)
              _InfoRow(
                icon: AppIcons.routeMile,
                label: 'markerSheet.mile'.tr(),
                value: info.distance!,
                showDivider: false,
              ),
            if (showActionButton) ...[
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColor.kPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'markerSheet.toGoThere'.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.navigation_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
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
          child: SizedBox(
            width: 64,
            height: 64,
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
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColor.black,
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColor.grey2),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    icon,
                    width: 17,
                    height: 17,
                    colorFilter: ColorFilter.mode(
                      AppColor.grey,
                      BlendMode.srcIn,
                    ),
                  ),
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
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColor.black,
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: AppColor.grey2),
          ),
      ],
    );
  }
}

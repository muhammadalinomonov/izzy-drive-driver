import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/core/constants/color/app_icons.dart';
import 'package:taxi_app/features/trips/data/model/route_support_model.dart';
import 'package:taxi_app/features/trips/presentation/widgets/dashed_leader.dart';

/// The white route card that sits inside a support bubble.
///
/// One widget covers both cards in the design: the driver's request, which
/// pairs the endpoints with the fuel/toll/mile figures (docs/ui/8-2-1.png),
/// and support's suggestion, which lists the priced stops between them
/// (docs/ui/8-2-2.png). Which one you get follows the data - see
/// [RouteSupportRouteCard].
class RouteSupportCard extends StatelessWidget {
  const RouteSupportCard({super.key, required this.card});

  final RouteSupportRouteCard card;

  @override
  Widget build(BuildContext context) {
    final summary = card.summary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EndpointRow(icon: AppIcons.tripOrigin, label: card.originLabel),
          for (final stop in card.stops) ...[
            const SizedBox(height: 10),
            _StopRow(stop: stop),
            const SizedBox(height: 10),
          ],
          if (card.stops.isEmpty) const SizedBox(height: 10),
          _EndpointRow(
            icon: AppIcons.tripDestination,
            label: card.destinationLabel,
          ),
          if (summary != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _SummaryBox(
                  label: 'routeOverview.fuel'.tr(),
                  value: summary.fuel,
                ),
                const SizedBox(width: 8),
                _SummaryBox(
                  label: 'routeOverview.toll'.tr(),
                  value: summary.toll,
                ),
                const SizedBox(width: 8),
                _SummaryBox(
                  label: 'routeOverview.mile'.tr(),
                  value: summary.distance,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Origin / destination: the tinted pin or finish flag against the address.
class _EndpointRow extends StatelessWidget {
  const _EndpointRow({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          icon,
          width: 18,
          height: 18,
          colorFilter: ColorFilter.mode(AppColor.darkGrey, BlendMode.srcIn),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, height: 1.35, color: AppColor.black),
          ),
        ),
      ],
    );
  }
}

/// A toll gantry or fuel station on a suggested route: bullet, address, then a
/// badge + optional distance, a dashed leader, and the price.
class _StopRow extends StatelessWidget {
  const _StopRow({required this.stop});

  final RouteSupportStop stop;

  @override
  Widget build(BuildContext context) {
    final isFuel = stop.kind == RouteSupportStopKind.fuel;
    // Same bullets the route overview timeline uses - red halo for tolls, blue
    // for fuel - so a stop reads identically wherever it appears.
    final bullet = isFuel ? AppIcons.fuelLeading : AppIcons.tollLeading;
    final badge = isFuel
        ? 'routeOverview.fuelStation'.tr()
        : 'routeOverview.toll'.tr();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nudged onto the first line of the title rather than the top of the
        // block, which is where the design sits it on wrapped addresses.
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: SvgPicture.asset(bullet, width: 16, height: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                stop.title,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: AppColor.black,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _Badge(text: badge),
                  if (stop.confirmed) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.check_circle,
                      size: 15,
                      color: AppColor.kPrimaryColor,
                    ),
                  ],
                  if (stop.distanceMiles != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      'routeOverview.inMiles'.tr(
                        namedArgs: {
                          'miles': stop.distanceMiles!.toStringAsFixed(0),
                        },
                      ),
                      style: TextStyle(fontSize: 13, color: AppColor.grey),
                    ),
                  ],
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: DashedLeader(),
                    ),
                  ),
                  if (stop.priceText.isNotEmpty)
                    Text(
                      stop.priceText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColor.black,
                      ),
                    ),
                  if (stop.priceNote.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      stop.priceNote,
                      style: TextStyle(fontSize: 12, color: AppColor.grey),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Outlined pill naming what a stop is.
class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.kPrimaryColor.withAlpha(90)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: AppColor.kPrimaryColor),
      ),
    );
  }
}

/// One of the three figures under the driver's route card.
class _SummaryBox extends StatelessWidget {
  const _SummaryBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    // Equal thirds rather than content-sized: the localized labels differ a
    // lot in length ("Пошлина" vs "Toll") and would otherwise stagger.
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColor.grey2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: AppColor.grey),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColor.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A dispatcher-recommended fuel stop with its accept action
/// (docs/mobile-chat-route-fuel-drive.md §5).
///
/// Separate from the stop row inside [RouteSupportCard], which only *shows*
/// the station: confirming is what puts it on the navigation route, so it
/// needs its own affordance rather than being buried in the route summary.
/// Shown only while the stop is still unconfirmed - once accepted, the row in
/// the card carries the check and this disappears.
class RouteFuelStopCard extends StatelessWidget {
  const RouteFuelStopCard({
    super.key,
    required this.recommendation,
    required this.onConfirm,
    this.confirming = false,
  });

  final RouteReviewFuelRecommendation recommendation;
  final VoidCallback onConfirm;

  /// The confirm call is in flight - the button holds its place and shows a
  /// spinner rather than the row collapsing.
  final bool confirming;

  @override
  Widget build(BuildContext context) {
    final price = recommendation.priceText;
    final miles = recommendation.distanceMiles;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SvgPicture.asset(
                  AppIcons.fuelLeading,
                  width: 16,
                  height: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      recommendation.stationName,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: AppColor.black,
                      ),
                    ),
                    if (recommendation.address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        recommendation.address,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: AppColor.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Badge(text: 'routeOverview.fuelStation'.tr()),
              if (miles != null) ...[
                const SizedBox(width: 8),
                Text(
                  'routeOverview.inMiles'.tr(
                    namedArgs: {'miles': miles.toStringAsFixed(0)},
                  ),
                  style: TextStyle(fontSize: 13, color: AppColor.grey),
                ),
              ],
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: DashedLeader(),
                ),
              ),
              if (price.isNotEmpty) ...[
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColor.black,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'routeSupport.forGallon'.tr(),
                  style: TextStyle(fontSize: 12, color: AppColor.grey),
                ),
              ],
            ],
          ),
          if (recommendation.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              recommendation.note,
              style: TextStyle(fontSize: 13, height: 1.35, color: AppColor.grey),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: confirming ? null : onConfirm,
              child: confirming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    )
                  : Text('routeSupport.confirmFuel'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}

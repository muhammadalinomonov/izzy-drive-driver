import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/location_service.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import 'package:taxi_app/src/features/trips/data/model/trip_model.dart';

/// One row of the trip-history list: origin -> destination, when it ran, and
/// the recommended alternative's distance / duration / toll.
class TripTile extends StatelessWidget {
  const TripTile({super.key, required this.trip, this.onTap, this.loading = false});

  final TripModel trip;
  final VoidCallback? onTap;

  /// True while the full route detail (`GET toll-routes/{id}`) for this tile
  /// is being fetched, e.g. after tapping it to open Route Overview.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final alternative = trip.primaryAlternative;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onTap,
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColor.grey2),
              ),
              child: Opacity(
                opacity: loading ? 0.5 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _Endpoints(trip: trip)),
                        _StatusChip(status: trip.status),
                      ],
                    ),
                    if (alternative != null) ...[
                      const SizedBox(height: 12),
                      Divider(color: AppColor.grey2, height: 1),
                      const SizedBox(height: 10),
                      _Metrics(alternative: alternative),
                    ],
                    if (trip.vehicle != null || trip.departureAt != null) ...[
                      const SizedBox(height: 10),
                      _Footer(trip: trip),
                    ],
                  ],
                ),
              ),
            ),
            if (loading)
              const Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2.2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Caches reverse-geocoded labels by coordinate so scrolling back over
/// already-resolved tiles doesn't re-hit the platform geocoder.
final Map<String, String> _addressCache = {};

class _Endpoints extends StatefulWidget {
  const _Endpoints({required this.trip});

  final TripModel trip;

  @override
  State<_Endpoints> createState() => _EndpointsState();
}

class _EndpointsState extends State<_Endpoints> {
  late String _origin = _cached(widget.trip.origin) ?? 'trips.origin'.tr();
  late String _destination =
      _cached(widget.trip.destination) ?? 'trips.destination'.tr();

  @override
  void initState() {
    super.initState();
    _resolve(widget.trip.origin, (label) => setState(() => _origin = label));
    _resolve(
      widget.trip.destination,
      (label) => setState(() => _destination = label),
    );
  }

  static String? _cached(TripCoordinate? point) {
    if (point == null) return null;
    return _addressCache[_key(point)];
  }

  static String _key(TripCoordinate point) =>
      '${point.lat.toStringAsFixed(5)},${point.lng.toStringAsFixed(5)}';

  /// The history endpoint returns raw coordinates, not geocoded names — there
  /// is no reverse-geocode field in the toll-route payload. Resolve a human
  /// label on-device via the platform geocoder, falling back to trimmed
  /// lat/lng if the lookup fails.
  Future<void> _resolve(TripCoordinate? point, void Function(String) apply) async {
    if (point == null) return;
    final cached = _cached(point);
    if (cached != null) return;

    final address = await serviceLocator<LocationService>()
        .getAddressFromLatLng(point.lat, point.lng);
    if (!mounted) return;

    final label = (address == null || address.trim().isEmpty)
        ? '${point.lat.toStringAsFixed(4)}, ${point.lng.toStringAsFixed(4)}'
        : address;
    _addressCache[_key(point)] = label;
    apply(label);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Point(
          icon: AppIcons.tripOrigin,
          color: AppColor.kPrimaryColor,
          label: _origin,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: SizedBox(
            height: 14,
            child: VerticalDivider(color: AppColor.grey2, width: 1, thickness: 1),
          ),
        ),
        _Point(
          icon: AppIcons.tripDestination,
          color: AppColor.red,
          label: _destination,
        ),
      ],
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.color, required this.label});

  final String icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: SvgPicture.asset(
            icon,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColor.black,
            ),
          ),
        ),
      ],
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.alternative});

  final TripAlternative alternative;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Metric(
          icon: Icons.straighten,
          value: _distance(alternative.distanceMeters),
        ),
        const SizedBox(width: 16),
        _Metric(
          icon: Icons.schedule,
          value: _duration(alternative.durationSeconds),
        ),
        const Spacer(),
        if (alternative.toll != null)
          Text(
            alternative.toll!.formatted,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColor.kPrimaryColor,
            ),
          ),
      ],
    );
  }

  static String _distance(int meters) {
    final miles = meters / 1609.344;
    return '${miles.toStringAsFixed(miles >= 100 ? 0 : 1)} mi';
  }

  static String _duration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours == 0) return '${minutes}m';
    return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColor.darkGrey),
        const SizedBox(width: 5),
        Text(value, style: TextStyle(fontSize: 13, color: AppColor.grey)),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.trip});

  final TripModel trip;

  @override
  Widget build(BuildContext context) {
    final date = trip.departureAt ?? trip.createdAt;
    return Row(
      children: [
        if (trip.vehicle != null)
          Flexible(
            child: Text(
              trip.vehicle!.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: AppColor.darkGrey),
            ),
          ),
        if (trip.vehicle != null && date != null)
          Text(' · ', style: TextStyle(fontSize: 12, color: AppColor.darkGrey)),
        if (date != null)
          Text(
            DateFormat('d MMM yyyy, HH:mm').format(date.toLocal()),
            style: TextStyle(fontSize: 12, color: AppColor.darkGrey),
          ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    // `calculated` is the steady state and carries no information worth a
    // chip - only the in-progress and failed states get called out.
    if (status == TripStatus.calculated) return const SizedBox.shrink();

    final (label, color) = switch (status) {
      TripStatus.calculating => ('trips.status.calculating'.tr(), AppColor.yellow),
      TripStatus.failed => ('trips.status.failed'.tr(), AppColor.red),
      _ => ('trips.status.unknown'.tr(), AppColor.darkGrey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

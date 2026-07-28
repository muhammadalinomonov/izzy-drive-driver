import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:taxi_app/src/core/components/app_snack_bar.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/utils/polyline_codec.dart';
import 'package:taxi_app/src/features/trips/data/model/place_model.dart';
import 'package:taxi_app/src/features/trips/data/model/trip_model.dart';
import 'package:taxi_app/src/features/trips/presentation/bloc/route_overview/route_overview_bloc.dart';
import 'package:taxi_app/src/features/trips/presentation/pages/driving_mode_page.dart';
import 'package:taxi_app/src/features/trips/presentation/utils/marker_icon.dart';
import 'package:taxi_app/src/routes/pages.dart';

/// Everything the route overview screen needs that isn't already inside the
/// `TripModel` (which only carries raw origin/destination coordinates, not
/// the human-readable labels the driver searched for).
class RouteOverviewArgs {
  final TripModel trip;
  final PlaceModel origin;
  final PlaceModel destination;

  const RouteOverviewArgs({
    required this.trip,
    required this.origin,
    required this.destination,
  });
}

/// Route overview (docs/ui/8.png): a full-screen map showing every priced
/// alternative, with the selected one emphasized and its toll markers
/// pinned, plus a draggable sheet to switch alternatives and start
/// navigation.
class RouteOverviewPage extends StatefulWidget {
  const RouteOverviewPage({super.key, required this.args});

  final RouteOverviewArgs args;

  @override
  State<RouteOverviewPage> createState() => _RouteOverviewPageState();
}

class _RouteOverviewPageState extends State<RouteOverviewPage> {
  static const double _collapsed = 0.34;
  static const double _half = 0.48;
  static const double _expanded = 0.85;

  final _sheetController = DraggableScrollableController();

  mapbox.MapboxMap? _map;
  mapbox.PolylineAnnotationManager? _lines;
  mapbox.PointAnnotationManager? _markers;

  /// Only re-fit the camera when the alternative actually changes, not on
  /// every rebuild the bloc triggers.
  String? _renderedAlternativeId;

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _onMapCreated(mapbox.MapboxMap map) {
    _map = map;
    map.style.setProjection(
      mapbox.StyleProjection(name: mapbox.StyleProjectionName.mercator),
    );
    map.scaleBar.updateSettings(mapbox.ScaleBarSettings(enabled: false));
    map.compass.updateSettings(mapbox.CompassSettings(enabled: false));
    _renderRoute(context.read<RouteOverviewBloc>().state);
  }

  Future<void> _renderRoute(RouteOverviewState state) async {
    final map = _map;
    if (map == null) return;
    if (_renderedAlternativeId == state.selectedAlternativeId) return;
    _renderedAlternativeId = state.selectedAlternativeId;

    _lines ??= await map.annotations.createPolylineAnnotationManager();
    _markers ??= await map.annotations.createPointAnnotationManager();
    if (!mounted) return;
    final lines = _lines!;
    final markers = _markers!;
    await lines.deleteAll();
    await markers.deleteAll();
    if (!mounted) return;

    final selected = state.selectedAlternative;
    if (selected == null) return;

    // Alternatives first, thin and muted, so the emphasized selected route
    // draws on top of them.
    for (final alt in state.alternatives) {
      if (alt.id == selected.id) continue;
      final points = decodePolyline(alt.polyline);
      if (points.isEmpty) continue;
      await lines.create(mapbox.PolylineAnnotationOptions(
        geometry: mapbox.LineString(
          coordinates: points.map((p) => mapbox.Position(p.longitude, p.latitude)).toList(),
        ),
        lineColor: AppColor.lightGreyBlue.toARGB32(),
        lineWidth: 4,
      ));
    }

    final selectedPoints = decodePolyline(selected.polyline);
    if (selectedPoints.isNotEmpty) {
      await lines.create(mapbox.PolylineAnnotationOptions(
        geometry: mapbox.LineString(
          coordinates:
              selectedPoints.map((p) => mapbox.Position(p.longitude, p.latitude)).toList(),
        ),
        lineColor: AppColor.kPrimaryColor.toARGB32(),
        lineWidth: 6,
      ));
    }
    if (!mounted) return;

    final originPoint = mapbox.Point(
      coordinates: mapbox.Position(
        widget.args.origin.coordinate.lng,
        widget.args.origin.coordinate.lat,
      ),
    );
    final destinationPoint = mapbox.Point(
      coordinates: mapbox.Position(
        widget.args.destination.coordinate.lng,
        widget.args.destination.coordinate.lat,
      ),
    );

    final originPng = await rasterizeMarkerSvg('assets/icons/currner_point_marker.svg');
    final destinationPng = await rasterizeMarkerSvg('assets/icons/finish_marker.svg');
    if (!mounted) return;
    await markers.create(mapbox.PointAnnotationOptions(
      geometry: originPoint,
      image: originPng,
      iconSize: 1.4,
      iconAnchor: mapbox.IconAnchor.BOTTOM,
    ));
    await markers.create(mapbox.PointAnnotationOptions(
      geometry: destinationPoint,
      image: destinationPng,
      iconSize: 1.4,
      iconAnchor: mapbox.IconAnchor.BOTTOM,
    ));
    if (!mounted) return;

    // Toll gantries are the only per-station markers the toll API returns
    // coordinates for (no fuel-station coordinates - see route_overview_bloc
    // for context); one pin per entry.
    if (selected.tollMarkers.isNotEmpty) {
      final tollPng = await rasterizeMarkerSvg(AppIcons.tollMarker, height: 72);
      if (!mounted) return;
      for (final toll in selected.tollMarkers) {
        await markers.create(mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position(toll.coordinate.lng, toll.coordinate.lat),
          ),
          image: tollPng,
          iconSize: 1.1,
          iconAnchor: mapbox.IconAnchor.BOTTOM,
        ));
      }
    }
    if (!mounted) return;

    final coordinates = <mapbox.Point>[
      originPoint,
      destinationPoint,
      ...selectedPoints.map((p) => mapbox.Point(coordinates: mapbox.Position(p.longitude, p.latitude))),
    ];
    final sheetHeightPx = MediaQuery.sizeOf(context).height * _collapsed;
    final camera = await map.cameraForCoordinatesPadding(
      coordinates,
      mapbox.CameraOptions(),
      mapbox.MbxEdgeInsets(top: 100, left: 48, right: 48, bottom: sheetHeightPx + 24),
      null,
      null,
    );
    if (!mounted) return;
    await map.flyTo(camera, mapbox.MapAnimationOptions(duration: 700));
  }

  void _onAlternativeSelected(String alternativeId) {
    context.read<RouteOverviewBloc>().add(RouteOverviewAlternativeSelected(alternativeId));
  }

  void _onStart() {
    context.read<RouteOverviewBloc>().add(const RouteOverviewStartPressed());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      body: BlocConsumer<RouteOverviewBloc, RouteOverviewState>(
        listenWhen: (p, c) =>
            p.selectedAlternativeId != c.selectedAlternativeId ||
            p.startTick != c.startTick ||
            p.startStatus != c.startStatus,
        listener: (context, state) {
          _renderRoute(state);
          if (state.startStatus == RouteOverviewStartStatus.failure &&
              state.startError.isNotEmpty) {
            AppSnackBar.showError(context, state.startError);
          }
          final session = state.session;
          if (session != null && state.startTick > 0) {
            context.push(
              Pages.drivingMode,
              extra: DrivingModeArgs(
                session: session,
                destinationLabel: widget.args.destination.fieldLabel,
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            fit: StackFit.expand,
            children: [
              mapbox.MapWidget(
                key: const ValueKey('routeOverviewMap'),
                styleUri: mapbox.MapboxStyles.STANDARD,
                onMapCreated: _onMapCreated,
                cameraOptions: mapbox.CameraOptions(
                  center: mapbox.Point(
                    coordinates: mapbox.Position(
                      widget.args.origin.coordinate.lng,
                      widget.args.origin.coordinate.lat,
                    ),
                  ),
                  zoom: 10.0,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: _CircleButton(
                      icon: Icons.arrow_back,
                      onTap: () => context.pop(),
                    ),
                  ),
                ),
              ),
              _RouteSheet(
                controller: _sheetController,
                collapsed: _collapsed,
                half: _half,
                expanded: _expanded,
                args: widget.args,
                state: state,
                onAlternativeSelected: _onAlternativeSelected,
                onStart: _onStart,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RouteSheet extends StatelessWidget {
  const _RouteSheet({
    required this.controller,
    required this.collapsed,
    required this.half,
    required this.expanded,
    required this.args,
    required this.state,
    required this.onAlternativeSelected,
    required this.onStart,
  });

  final DraggableScrollableController controller;
  final double collapsed;
  final double half;
  final double expanded;
  final RouteOverviewArgs args;
  final RouteOverviewState state;
  final ValueChanged<String> onAlternativeSelected;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: half,
      minChildSize: collapsed,
      maxChildSize: expanded,
      snap: true,
      snapSizes: [collapsed, half, expanded],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(28),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColor.grey2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: !state.hasAlternatives
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'routeOverview.noRoutes'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColor.grey),
                          ),
                        ),
                      )
                    : ListView(
                        controller: scrollController,
                        padding: EdgeInsets.zero,
                        children: [
                          _AlternativeTabs(
                            trip: state.trip,
                            selectedId: state.selectedAlternativeId,
                            onSelected: onAlternativeSelected,
                          ),
                          Divider(color: AppColor.grey2, height: 1),
                          _WaypointList(args: args, alternative: state.selectedAlternative!),
                          Divider(color: AppColor.grey2, height: 1),
                          _ServicesRow(alternative: state.selectedAlternative!),
                        ],
                      ),
              ),
              if (state.hasAlternatives)
                _StartBar(
                  loading: state.startStatus == RouteOverviewStartStatus.loading,
                  onPressed: onStart,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AlternativeTabs extends StatelessWidget {
  const _AlternativeTabs({
    required this.trip,
    required this.selectedId,
    required this.onSelected,
  });

  final TripModel trip;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    var alternativeIndex = 0;
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: trip.alternatives.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final alt = trip.alternatives[index];
          final isRecommended = alt.id == trip.recommendedAlternativeId;
          if (!isRecommended) alternativeIndex++;
          final label = isRecommended
              ? 'routeOverview.recommended'.tr()
              : 'routeOverview.alternative'.tr(namedArgs: {'index': '$alternativeIndex'});
          final selected = alt.id == selectedId;
          return _AlternativeChip(
            label: label,
            distanceMiles: alt.distanceMiles,
            total: alt.total,
            selected: selected,
            onTap: () => onSelected(alt.id),
          );
        },
      ),
    );
  }
}

class _AlternativeChip extends StatelessWidget {
  const _AlternativeChip({
    required this.label,
    required this.distanceMiles,
    required this.total,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final double distanceMiles;
  final TripMoney? total;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColor.kPrimary2Color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColor.kPrimaryColor : AppColor.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              total == null
                  ? '${distanceMiles.toStringAsFixed(0)} mi'
                  : '${distanceMiles.toStringAsFixed(0)} mi • -${total!.formatted}',
              style: TextStyle(fontSize: 11, color: AppColor.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaypointList extends StatelessWidget {
  const _WaypointList({required this.args, required this.alternative});

  final RouteOverviewArgs args;
  final TripAlternative alternative;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WaypointRow(
            icon: AppIcons.routeLocation,
            title: args.origin.fieldLabel,
          ),
          // The toll API gives each toll marker's name/coordinate/amount but
          // no distance-from-start, so the row shows only the amount, not
          // "in X mi" as in docs/ui/8.png.
          for (final toll in alternative.tollMarkers)
            _WaypointRow(
              icon: AppIcons.routeToll,
              title: toll.name,
              badge: 'Toll',
              trailing: toll.amount?.formatted,
            ),
          _WaypointRow(
            icon: AppIcons.tripDestination,
            title: args.destination.fieldLabel,
          ),
        ],
      ),
    );
  }
}

class _WaypointRow extends StatelessWidget {
  const _WaypointRow({
    required this.icon,
    required this.title,
    this.badge,
    this.trailing,
  });

  final String icon;
  final String title;
  final String? badge;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            icon,
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(AppColor.darkGrey, BlendMode.srcIn),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColor.black,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColor.grey2,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(fontSize: 10, color: AppColor.darkGrey),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColor.grey,
              ),
            ),
        ],
      ),
    );
  }
}

class _ServicesRow extends StatelessWidget {
  const _ServicesRow({required this.alternative});

  final TripAlternative alternative;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ServiceStat(
            icon: AppIcons.routeFuel,
            value: alternative.fuel == null ? '-' : '-${alternative.fuel!.formatted}',
          ),
          _ServiceStat(
            icon: AppIcons.routeToll,
            value: alternative.toll == null ? '-' : '-${alternative.toll!.formatted}',
          ),
          _ServiceStat(
            icon: AppIcons.routeLocation,
            value: '${alternative.distanceMiles.toStringAsFixed(0)} mi',
          ),
        ],
      ),
    );
  }
}

class _ServiceStat extends StatelessWidget {
  const _ServiceStat({required this.icon, required this.value});

  final String icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(icon, width: 20, height: 20),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.black),
        ),
      ],
    );
  }
}

class _StartBar extends StatelessWidget {
  const _StartBar({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: loading ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColor.kPrimaryColor,
              disabledBackgroundColor: AppColor.kPrimaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    'routeOverview.start'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: AppColor.black),
        ),
      ),
    );
  }
}

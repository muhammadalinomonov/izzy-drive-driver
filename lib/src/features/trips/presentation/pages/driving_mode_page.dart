import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/utils/polyline_codec.dart';
import 'package:taxi_app/src/features/trips/data/model/navigation_session_model.dart';
import 'package:taxi_app/src/features/trips/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:taxi_app/src/features/trips/presentation/utils/marker_icon.dart';

/// The session created in Route Overview plus the human-readable destination
/// label (the session itself only carries raw lat/lng, per
/// `NavigationSessionModel.destination`).
class DrivingModeArgs {
  final NavigationSessionModel session;
  final String destinationLabel;

  const DrivingModeArgs({required this.session, required this.destinationLabel});
}

/// Driving Mode (docs/ui/9.png): live turn-by-turn following of the session
/// started in Route Overview.
class DrivingModePage extends StatefulWidget {
  const DrivingModePage({super.key, required this.args});

  final DrivingModeArgs args;

  @override
  State<DrivingModePage> createState() => _DrivingModePageState();
}

class _DrivingModePageState extends State<DrivingModePage> with WidgetsBindingObserver {
  mapbox.MapboxMap? _map;
  mapbox.PolylineAnnotationManager? _lines;
  mapbox.PointAnnotationManager? _markers;
  String? _renderedSessionId;
  bool _cameraFollowing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<NavigationBloc>().add(const NavigationStarted());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<NavigationBloc>().add(const NavigationResumeRequested());
    }
  }

  void _onMapCreated(mapbox.MapboxMap map) {
    _map = map;
    map.style.setProjection(
      mapbox.StyleProjection(name: mapbox.StyleProjectionName.mercator),
    );
    map.scaleBar.updateSettings(mapbox.ScaleBarSettings(enabled: false));
    map.compass.updateSettings(mapbox.CompassSettings(enabled: false));
    final session = context.read<NavigationBloc>().state.session;
    if (session != null) _renderSession(session);
  }

  Future<void> _renderSession(NavigationSessionModel session) async {
    final map = _map;
    if (map == null || _renderedSessionId == session.id) return;
    _renderedSessionId = session.id;

    _lines ??= await map.annotations.createPolylineAnnotationManager();
    _markers ??= await map.annotations.createPointAnnotationManager();
    if (!mounted) return;

    await _lines!.deleteAll();
    await _markers!.deleteAll();
    if (!mounted) return;

    final points = decodePolyline(session.route.polyline);
    if (points.isNotEmpty) {
      await _lines!.create(mapbox.PolylineAnnotationOptions(
        geometry: mapbox.LineString(
          coordinates: points.map((p) => mapbox.Position(p.longitude, p.latitude)).toList(),
        ),
        lineColor: AppColor.kPrimaryColor.toARGB32(),
        lineWidth: 6,
      ));
    }
    if (!mounted) return;

    final destinationPng = await rasterizeMarkerSvg('assets/icons/finish_marker.svg');
    if (!mounted) return;
    await _markers!.create(mapbox.PointAnnotationOptions(
      geometry: mapbox.Point(
        coordinates:
            mapbox.Position(session.destination.lng, session.destination.lat),
      ),
      image: destinationPng,
      iconSize: 1.4,
      iconAnchor: mapbox.IconAnchor.BOTTOM,
    ));
    if (!mounted) return;

    // Same toll-only marker set as route overview - see
    // route_overview_bloc.dart for why fuel stations have no map pin.
    if (session.routeAlternative.tollMarkers.isNotEmpty) {
      final tollPng = await rasterizeMarkerSvg(AppIcons.tollMarker, height: 72);
      if (!mounted) return;
      for (final toll in session.routeAlternative.tollMarkers) {
        await _markers!.create(mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position(toll.coordinate.lng, toll.coordinate.lat),
          ),
          image: tollPng,
          iconSize: 1.1,
          iconAnchor: mapbox.IconAnchor.BOTTOM,
        ));
      }
    }
  }

  Future<void> _followCamera(NavigationState state) async {
    final map = _map;
    final position = state.lastPosition;
    if (map == null || position == null || !_cameraFollowing) return;
    await map.easeTo(
      mapbox.CameraOptions(
        center: mapbox.Point(coordinates: mapbox.Position(position.longitude, position.latitude)),
        zoom: 17,
        bearing: position.heading >= 0 ? position.heading : null,
      ),
      mapbox.MapAnimationOptions(duration: 600),
    );
  }

  void _onRecenter() {
    setState(() => _cameraFollowing = true);
    final state = context.read<NavigationBloc>().state;
    _followCamera(state);
  }

  void _onCancel() {
    context.read<NavigationBloc>().add(const NavigationCancelPressed());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      body: BlocConsumer<NavigationBloc, NavigationState>(
        listenWhen: (p, c) =>
            p.session?.id != c.session?.id ||
            p.lastPosition != c.lastPosition ||
            p.status != c.status,
        listener: (context, state) {
          final session = state.session;
          if (session != null) _renderSession(session);
          _followCamera(state);
          if (state.status == NavigationPageStatus.closed) {
            context.pop();
          }
        },
        builder: (context, state) {
          final session = state.session ?? widget.args.session;
          return Stack(
            fit: StackFit.expand,
            children: [
              mapbox.MapWidget(
                key: const ValueKey('drivingModeMap'),
                styleUri: mapbox.MapboxStyles.STANDARD,
                onMapCreated: _onMapCreated,
                cameraOptions: mapbox.CameraOptions(
                  center: mapbox.Point(
                    coordinates: mapbox.Position(
                      session.destination.lng,
                      session.destination.lat,
                    ),
                  ),
                  zoom: 14.0,
                ),
              ),
              if (state.status == NavigationPageStatus.loading)
                const Center(child: CircularProgressIndicator.adaptive()),
              if (state.status == NavigationPageStatus.error)
                _ErrorOverlay(
                  message: state.errorMessage,
                  onBack: () => context.pop(),
                  onRetry: () =>
                      context.read<NavigationBloc>().add(const NavigationResumeRequested()),
                ),
              if (state.status != NavigationPageStatus.error &&
                  session.route.maneuvers.isNotEmpty)
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 12,
                  left: 16,
                  right: 76,
                  child: _ManeuverBanner(
                    maneuver: session.progress.nextManeuver ?? session.route.maneuvers.first,
                    rerouting: state.status == NavigationPageStatus.rerouting,
                  ),
                ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 12,
                right: 16,
                child: _CircleButton(icon: AppIcons.gpsRecenter, onTap: _onRecenter),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 12,
                left: 16,
                child: session.route.maneuvers.isEmpty
                    ? _CircleButton(iconData: Icons.arrow_back, onTap: () => context.pop())
                    : const SizedBox.shrink(),
              ),
              _BottomBar(
                destinationLabel: widget.args.destinationLabel,
                progress: session.progress,
                onCancel: _onCancel,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({
    required this.message,
    required this.onBack,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(140),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.isEmpty ? 'common.somethingWentWrong'.tr() : message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColor.black),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(onPressed: onBack, child: Text('common.back'.tr())),
                const SizedBox(width: 8),
                FilledButton(onPressed: onRetry, child: Text('common.retry'.tr())),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ManeuverBanner extends StatelessWidget {
  const _ManeuverBanner({required this.maneuver, required this.rerouting});

  final ManeuverModel maneuver;
  final bool rerouting;

  IconData get _icon {
    return switch (maneuver.modifier) {
      'left' => Icons.turn_left,
      'sharp left' => Icons.turn_sharp_left,
      'slight left' => Icons.turn_slight_left,
      'right' => Icons.turn_right,
      'sharp right' => Icons.turn_sharp_right,
      'slight right' => Icons.turn_slight_right,
      'uturn' => Icons.u_turn_left,
      _ => Icons.straight,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColor.kPrimaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(_icon, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _distanceLabel(maneuver.distanceMeters),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  rerouting ? 'drivingMode.rerouting'.tr() : maneuver.instruction,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _distanceLabel(int meters) {
    final miles = meters / 1609.344;
    return '${miles.toStringAsFixed(miles >= 10 ? 0 : 1)} mi';
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.destinationLabel,
    required this.progress,
    required this.onCancel,
  });

  final String destinationLabel;
  final NavigationProgress progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(28), blurRadius: 16),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      destinationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColor.black,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: Icon(Icons.close, size: 16, color: AppColor.red),
                    label: Text(
                      'drivingMode.cancel'.tr(),
                      style: TextStyle(color: AppColor.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _distance(progress.remainingDistanceMeters),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.black),
                  ),
                  Text(
                    _duration(progress.remainingDurationSeconds),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.black),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (progress.percent / 100).clamp(0, 1),
                  minHeight: 5,
                  backgroundColor: AppColor.grey2,
                  valueColor: AlwaysStoppedAnimation(AppColor.kPrimaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
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

class _CircleButton extends StatelessWidget {
  const _CircleButton({this.icon, this.iconData, required this.onTap});

  /// SVG asset path, mutually exclusive with [iconData].
  final String? icon;
  final IconData? iconData;
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
          child: Center(
            child: icon != null
                ? SvgPicture.asset(icon!, width: 20, height: 20)
                : Icon(iconData, size: 20, color: AppColor.black),
          ),
        ),
      ),
    );
  }
}

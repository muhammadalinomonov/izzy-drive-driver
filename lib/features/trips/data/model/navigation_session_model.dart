import 'package:taxi_app/core/utils/json_safe.dart';
import 'package:taxi_app/features/trips/data/model/trip_model.dart';

/// Models for `mobile/navigation-sessions` (Quadrix Tolling).
///
/// Shapes follow `docs/mobile-api.md` §5. A navigation session is created
/// from one `TripAlternative` chosen off a `TripModel` (route request) and
/// tracks turn-by-turn guidance + GPS progress for Driving Mode.

enum NavigationSessionStatus {
  active,
  completed,
  cancelled,
  unknown;

  static NavigationSessionStatus parse(String raw) {
    return switch (raw.toLowerCase()) {
      'active' => NavigationSessionStatus.active,
      'completed' => NavigationSessionStatus.completed,
      'cancelled' => NavigationSessionStatus.cancelled,
      _ => NavigationSessionStatus.unknown,
    };
  }
}

/// One turn instruction (`Maneuver` object, docs/mobile-api.md §5).
class ManeuverModel {
  final int index;
  final String instruction;
  final String type;
  final String modifier;
  final String name;
  final int distanceMeters;
  final int durationSeconds;
  final int distanceFromStartMeters;
  final TripCoordinate? location;

  const ManeuverModel({
    required this.index,
    required this.instruction,
    required this.type,
    required this.modifier,
    required this.name,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.distanceFromStartMeters,
    required this.location,
  });

  factory ManeuverModel.fromJson(Map<String, dynamic> json) {
    final locationRaw = json['location'];
    return ManeuverModel(
      index: toInt(json['index']),
      instruction: toStr(json['instruction']),
      type: toStr(json['type']),
      modifier: toStr(json['modifier']),
      name: toStr(json['name']),
      distanceMeters: toInt(json['distance_meters']),
      durationSeconds: toInt(json['duration_seconds']),
      distanceFromStartMeters: toInt(json['distance_from_start_meters']),
      location:
          locationRaw == null ? null : TripCoordinate.fromJson(toMap(locationRaw)),
    );
  }
}

/// OSRM-guided route geometry + turn list (`route` object, §5).
class NavigationRoute {
  final String polyline;
  final int distanceMeters;
  final int durationSeconds;
  final List<ManeuverModel> maneuvers;
  final String attribution;

  const NavigationRoute({
    required this.polyline,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.maneuvers,
    required this.attribution,
  });

  factory NavigationRoute.fromJson(Map<String, dynamic> json) {
    return NavigationRoute(
      polyline: toStr(json['polyline']),
      distanceMeters: toInt(json['distance_meters']),
      durationSeconds: toInt(json['duration_seconds']),
      maneuvers: toList(json['maneuvers'], (e) => ManeuverModel.fromJson(toMap(e))),
      attribution: toStr(json['attribution']),
    );
  }
}

/// GPS-driven progress along the session's route (`progress` object, §5).
class NavigationProgress {
  final int currentStepIndex;
  final ManeuverModel? nextManeuver;
  final double percent;
  final int remainingDistanceMeters;
  final int remainingDurationSeconds;
  final bool offRoute;
  final int rerouteCount;

  const NavigationProgress({
    required this.currentStepIndex,
    required this.nextManeuver,
    required this.percent,
    required this.remainingDistanceMeters,
    required this.remainingDurationSeconds,
    required this.offRoute,
    required this.rerouteCount,
  });

  factory NavigationProgress.fromJson(Map<String, dynamic> json) {
    final nextManeuverRaw = json['next_maneuver'];
    return NavigationProgress(
      currentStepIndex: toInt(json['current_step_index']),
      nextManeuver: nextManeuverRaw == null
          ? null
          : ManeuverModel.fromJson(toMap(nextManeuverRaw)),
      percent: toDouble(json['percent']),
      remainingDistanceMeters: toInt(json['remaining_distance_meters']),
      remainingDurationSeconds: toInt(json['remaining_duration_seconds']),
      offRoute: toBool(json['off_route']),
      rerouteCount: toInt(json['reroute_count']),
    );
  }

  static const empty = NavigationProgress(
    currentStepIndex: 0,
    nextManeuver: null,
    percent: 0,
    remainingDistanceMeters: 0,
    remainingDurationSeconds: 0,
    offRoute: false,
    rerouteCount: 0,
  );
}

/// Last reported GPS fix (`last_location` object, §5).
class NavigationLocation {
  final DateTime? occurredAt;
  final double latitude;
  final double longitude;
  final double? speedMph;
  final double? headingDegrees;

  const NavigationLocation({
    required this.occurredAt,
    required this.latitude,
    required this.longitude,
    required this.speedMph,
    required this.headingDegrees,
  });

  factory NavigationLocation.fromJson(Map<String, dynamic> json) {
    final occurredRaw = toStrNullable(json['occurred_at']);
    return NavigationLocation(
      occurredAt: occurredRaw == null ? null : DateTime.tryParse(occurredRaw),
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
      speedMph: json['speed_mph'] == null ? null : toDouble(json['speed_mph']),
      headingDegrees:
          json['heading_degrees'] == null ? null : toDouble(json['heading_degrees']),
    );
  }
}

/// A `NavigationSession` (docs/mobile-api.md §5) — the active turn-by-turn
/// guidance + progress for one chosen route alternative.
class NavigationSessionModel {
  final String id;
  final NavigationSessionStatus status;
  final String routeRequestId;
  final TripAlternative routeAlternative;
  final NavigationRoute route;
  final NavigationProgress progress;
  final NavigationLocation? lastLocation;
  final TripCoordinate destination;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  const NavigationSessionModel({
    required this.id,
    required this.status,
    required this.routeRequestId,
    required this.routeAlternative,
    required this.route,
    required this.progress,
    required this.lastLocation,
    required this.destination,
    required this.startedAt,
    required this.completedAt,
    required this.cancelledAt,
  });

  factory NavigationSessionModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic raw) {
      final value = toStrNullable(raw);
      return value == null ? null : DateTime.tryParse(value);
    }

    final lastLocationRaw = json['last_location'];

    return NavigationSessionModel(
      id: toStr(json['id']),
      status: NavigationSessionStatus.parse(toStr(json['status'])),
      routeRequestId: toStr(json['route_request_id']),
      routeAlternative: TripAlternative.fromJson(toMap(json['route_alternative'])),
      route: NavigationRoute.fromJson(toMap(json['route'])),
      progress: json['progress'] == null
          ? NavigationProgress.empty
          : NavigationProgress.fromJson(toMap(json['progress'])),
      lastLocation: lastLocationRaw == null
          ? null
          : NavigationLocation.fromJson(toMap(lastLocationRaw)),
      destination: TripCoordinate.fromJson(toMap(json['destination'])),
      startedAt: parseDate(json['started_at']),
      completedAt: parseDate(json['completed_at']),
      cancelledAt: parseDate(json['cancelled_at']),
    );
  }

  bool get isActive => status == NavigationSessionStatus.active;
}

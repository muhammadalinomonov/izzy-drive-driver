/// Quadrix Tolling API — a SEPARATE backend from `api.izzydrive.com`.
///
/// Different host, different auth scheme (Laravel Sanctum instead of the
/// SimpleJWT pair used by [ApiConstants]), and it additionally requires an
/// `X-Organization-Id` header on every protected call. Keep these constants
/// out of `ApiConstants` so the two backends can never be mixed up by a
/// stray `client.get(ApiConstants.x)` against the wrong Dio.
///
/// Full endpoint reference: `docs/mobile-api.md`.
class TollApiConstants {
  TollApiConstants._();

  static const String baseUrl = 'https://toll-api.quadrix.ai/api/v1/';

  /// Header carrying the driver's organization ULID. Required by every
  /// protected endpoint; omitting it answers 400 ORGANIZATION_HEADER_REQUIRED.
  static const String organizationHeader = 'X-Organization-Id';

  // Auth
  static const String login = 'mobile/auth/login';
  static const String logout = 'mobile/auth/logout';

  /// The one authenticated endpoint that does NOT require
  /// [organizationHeader] - which makes it the bootstrap for discovering the
  /// driver's organization id (`data.memberships[].organization.id`).
  static const String me = 'auth/me';

  // Driver / app bootstrap
  static const String bootstrap = 'mobile/bootstrap';
  /// Driver profile: `GET` reads it, `PATCH` updates the editable fields
  /// (docs §3.2/§3.3). Note PATCH, not POST.
  static const String profile = 'mobile/profile';
  static const String vehicles = 'mobile/vehicles';
  static const String places = 'mobile/places';

  /// Background fleet GPS (docs §6.1). Deliberately NOT the navigation
  /// progress endpoint: per §6.1 this one does **not** advance a session's
  /// progress, next maneuver or off-route flag, and it requires a
  /// `vehicle_id`. During an active trip both are posted - this for fleet
  /// tracking, [navigationSessionLocations] for guidance.
  static const String locations = 'mobile/locations';

  // Toll routes (trip history + route calculation)
  static const String tollRoutes = 'mobile/toll-routes';

  static String tollRouteDetail(String routeRequestId) =>
      'mobile/toll-routes/$routeRequestId';

  /// `GET mobile/fuel-stations` (docs §7.1) — the managed EFS fuel-station
  /// catalogue. Read-only, active-only, and queried by bounding box rather
  /// than by centre+radius: there is no `lat`/`lng`/`radius` form, so a
  /// nearby search sends `north`/`south`/`east`/`west` together.
  ///
  /// Rate limit is 60 req/min, which is why bounds requests are debounced.
  static const String fuelStations = 'mobile/fuel-stations';

  // Navigation sessions
  static const String navigationSessions = 'mobile/navigation-sessions';
  static const String navigationSessionsCurrent =
      'mobile/navigation-sessions/current';

  static String navigationSessionLocations(String navigationSessionId) =>
      'mobile/navigation-sessions/$navigationSessionId/locations';

  static String navigationSessionReroute(String navigationSessionId) =>
      'mobile/navigation-sessions/$navigationSessionId/reroute';

  static String navigationSessionComplete(String navigationSessionId) =>
      'mobile/navigation-sessions/$navigationSessionId/complete';

  static String navigationSessionCancel(String navigationSessionId) =>
      'mobile/navigation-sessions/$navigationSessionId/cancel';
}

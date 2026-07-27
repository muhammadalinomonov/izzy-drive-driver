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
  static const String profile = 'mobile/profile';
  static const String vehicles = 'mobile/vehicles';
  static const String places = 'mobile/places';

  // Toll routes (trip history)
  static const String tollRoutes = 'mobile/toll-routes';

  static String tollRouteDetail(String routeRequestId) =>
      'mobile/toll-routes/$routeRequestId';
}

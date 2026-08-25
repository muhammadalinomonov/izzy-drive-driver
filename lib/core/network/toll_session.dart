import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:taxi_app/core/network/toll_api_constants.dart';
import 'package:taxi_app/core/network/token_service.dart';
import 'package:taxi_app/core/utils/json_safe.dart';

/// Credential holder for the Quadrix Tolling backend.
///
/// The app's primary session (`token`/`refresh` for `api.izzydrive.com`) is
/// NOT accepted here - `toll-api.quadrix.ai` issues its own Sanctum token via
/// `POST mobile/auth/login`. Until the driver app grows a real Quadrix sign-in
/// flow, the token is read from persisted storage first and falls back to
/// `.env`, so it can be supplied without shipping a login screen.
///
/// Token resolution order (first non-empty wins):
///   1. `StorageRepository` - written by [saveToken], survives restarts.
///   2. `.env` - `QUADRIX_TOLL_TOKEN`.
///
/// The organization id is NOT configured by hand: every protected endpoint
/// requires `X-Organization-Id`, and [ensureOrganizationId] discovers it from
/// `GET auth/me` (the only authenticated endpoint that works without the
/// header) and caches it. A token is therefore the sole credential needed.
class TollSession {
  TollSession._();

  static const String _tokenKey = 'toll_token';
  static const String _orgKey = 'toll_org_id';
  static const String _driverIdKey = 'toll_driver_id';
  static const String _routeReviewAvailableKey = 'toll_route_review_available';

  static const String _tokenEnv = 'QUADRIX_TOLL_TOKEN';
  static const String _orgEnv = 'QUADRIX_ORG_ID';

  /// Concurrent-resolve guard: parallel first requests converge on a single
  /// `auth/me` call instead of stampeding the backend.
  static Future<String>? _resolveFuture;

  /// Same guard as [_resolveFuture], for [ensureDriverId].
  static Future<String>? _driverIdResolveFuture;

  static String get token => _read(_tokenKey, _tokenEnv);

  /// Cached organization id, empty until [ensureOrganizationId] has run.
  static String get organizationId => _read(_orgKey, _orgEnv);

  /// Cached driver id, empty until [ensureDriverId] has run. No `.env`
  /// fallback - unlike the org id, nothing plausible could be guessed here.
  static String get driverId => StorageRepository.getString(_driverIdKey);

  /// Cached `data.services.route_review.available` from the same bootstrap
  /// call [ensureDriverId] already makes - see [ensureRouteReviewAvailable].
  /// Defaults `false`, same fail-closed reasoning as everything else here:
  /// a not-yet-resolved entitlement must hide the feature, not show it.
  static bool get routeReviewAvailable =>
      StorageRepository.getBool(_routeReviewAvailableKey);

  /// UI-facing view of [routeReviewAvailable], for widgets that must show or
  /// hide the paid-review entry points the moment bootstrap answers (§3.3,
  /// and §16's `MOBILE_ROUTE_REVIEW_NOT_ENABLED` -> "disable the paid review
  /// UI"). Same shape as `PremiumSession.listenable`, which the same buttons
  /// already listen to.
  ///
  /// Starts **optimistic**: an unanswered bootstrap is not a denial, and
  /// hiding "Send request" from a driver who does have the feature - every
  /// cold start, until the call returns - would be the worse failure. The
  /// create path in `RouteSupportBloc` re-checks before spending a request
  /// either way.
  static ValueListenable<bool> get routeReviewListenable =>
      _routeReviewNotifier;

  static final ValueNotifier<bool> _routeReviewNotifier =
      ValueNotifier<bool>(true);

  /// True when a bearer token exists - the only credential the caller must
  /// supply. Without it, every toll-API call is a guaranteed 401.
  static bool get hasToken => token.isNotEmpty;

  /// Returns the organization id, fetching and caching it on first use.
  /// Returns an empty string when there is no token or the lookup fails; the
  /// caller then sends no header and the backend answers
  /// 400 ORGANIZATION_HEADER_REQUIRED, which surfaces as a normal error.
  static Future<String> ensureOrganizationId() async {
    final cached = organizationId;
    if (cached.isNotEmpty) return cached;
    if (!hasToken) return '';
    return _resolveFuture ??= _fetchOrganizationId().whenComplete(() {
      _resolveFuture = null;
    });
  }

  static Future<String> _fetchOrganizationId() async {
    // A SEPARATE bare Dio with no interceptors - resolving the org id through
    // the main toll client would re-enter its onRequest and recurse.
    final dio = Dio(
      BaseOptions(
        baseUrl: TollApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    try {
      final response = await dio.get(TollApiConstants.me);
      final code = response.statusCode ?? 0;
      if (code < 200 || code >= 300) return '';
      final data = toMap(toMap(response.data)['data']);
      final memberships = data['memberships'];
      if (memberships is! List) return '';
      for (final raw in memberships) {
        final membership = toMap(raw);
        // Prefer an active driver membership - a user can belong to several
        // organizations, and the mobile endpoints are driver-scoped.
        final role = toStr(membership['role']).toLowerCase();
        final status = toStr(membership['status']).toLowerCase();
        if (role != 'driver' || status != 'active') continue;
        final id = _organizationIdOf(membership);
        if (id.isNotEmpty) {
          await StorageRepository.putString(_orgKey, id);
          return id;
        }
      }
      // No active driver membership - fall back to the first one that has an
      // organization at all, rather than failing outright.
      for (final raw in memberships) {
        final id = _organizationIdOf(toMap(raw));
        if (id.isNotEmpty) {
          await StorageRepository.putString(_orgKey, id);
          return id;
        }
      }
    } catch (e) {
      log('TollSession: organization lookup failed - $e');
    }
    return '';
  }

  static String _organizationIdOf(Map<String, dynamic> membership) {
    final nested = toStr(toMap(membership['organization'])['id']);
    return nested.isNotEmpty ? nested : toStr(membership['organization_id']);
  }

  /// Returns the driver id, fetching and caching it on first use. This is
  /// the id the Reverb private channel is keyed on -
  /// `private-support.driver.{driver_id}` (docs/support-chat-api.md §1) -
  /// not the toll organization id.
  ///
  /// Returns an empty string when there is no token, no organization (the
  /// bootstrap call needs [organizationHeader] too, unlike `auth/me`), or the
  /// lookup fails - callers treat that the same as "socket not available yet"
  /// rather than as an error.
  static Future<String> ensureDriverId() async {
    final cached = driverId;
    if (cached.isNotEmpty) return cached;
    if (!hasToken) return '';
    return _driverIdResolveFuture ??= _fetchDriverId().whenComplete(() {
      _driverIdResolveFuture = null;
    });
  }

  /// Same bootstrap call also carries `data.services.route_review.available`
  /// (docs/mobile-chat-complete-api-websocket.md §3.3) - fetched and cached
  /// here as a side effect rather than with a second round-trip, since
  /// nothing else on this response is needed yet. See
  /// [ensureRouteReviewAvailable].
  static Future<String> _fetchDriverId() async {
    final orgId = await ensureOrganizationId();
    if (orgId.isEmpty) return '';
    // Bare Dio, same reasoning as [_fetchOrganizationId] - independent of the
    // main toll client so this can be called from anywhere (including the
    // socket service) without depending on the DI container being ready.
    final dio = Dio(
      BaseOptions(
        baseUrl: TollApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          TollApiConstants.organizationHeader: orgId,
        },
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    try {
      final response = await dio.get(TollApiConstants.bootstrap);
      final code = response.statusCode ?? 0;
      if (code < 200 || code >= 300) return '';
      final data = toMap(toMap(response.data)['data']);
      final id = toStr(toMap(data['profile'])['id']);
      if (id.isNotEmpty) {
        await StorageRepository.putString(_driverIdKey, id);
      }
      // §3.3's `services.route_review.available`. A backend build that
      // predates that section sends no `services` block at all - absence is
      // "unknown", not "denied", so it must not latch the entitlement off and
      // block every create. Only an explicit `false` disables the feature.
      final routeReview = toMap(toMap(data['services'])['route_review']);
      final routeReviewAvailable = routeReview.containsKey('available')
          ? toBool(routeReview['available'])
          : true;
      await StorageRepository.putBool(
        key: _routeReviewAvailableKey,
        value: routeReviewAvailable,
      );
      _routeReviewNotifier.value = routeReviewAvailable;
      return id;
    } catch (e) {
      log('TollSession: driver id lookup failed - $e');
      return '';
    }
  }

  /// Whether the driver may create a new route review right now - **not**
  /// the same thing as the Premium `is_paid_user` entitlement
  /// (`PremiumSession.isPremium`). The doc is explicit that gating
  /// "Send request" on `is_paid_user` alone is wrong: `available` also folds
  /// in TollTally/plan availability that can be false for a paying driver
  /// (docs/mobile-chat-complete-api-websocket.md §3.3). Callers should check
  /// both.
  ///
  /// Shares [ensureDriverId]'s resolve-future and bootstrap call - awaiting
  /// this after (or concurrently with) [ensureDriverId] costs no extra
  /// request.
  static Future<bool> ensureRouteReviewAvailable() async {
    await ensureDriverId();
    return routeReviewAvailable;
  }

  static Future<void> saveToken(String value) async {
    await StorageRepository.putString(_tokenKey, value);
    // The cached org id, driver id and entitlement belong to the previous
    // token's user.
    await StorageRepository.deleteString(_orgKey);
    await StorageRepository.deleteString(_driverIdKey);
    await StorageRepository.deleteBool(_routeReviewAvailableKey);
    // Back to optimistic: the next driver's entitlement is unknown, not false.
    _routeReviewNotifier.value = true;
  }

  /// Stores both credentials from one `mobile/auth/login` response.
  ///
  /// Preferred over [saveToken] after a real sign-in: the login payload
  /// already carries the memberships, so seeding the org id here skips the
  /// `auth/me` round-trip [ensureOrganizationId] would otherwise make on the
  /// very next request. An empty [organizationId] falls back to that lookup.
  static Future<void> saveSession({
    required String token,
    String organizationId = '',
  }) async {
    await saveToken(token);
    if (organizationId.isNotEmpty) {
      await StorageRepository.putString(_orgKey, organizationId);
    }
  }

  static Future<void> clear() async {
    await StorageRepository.deleteString(_tokenKey);
    await StorageRepository.deleteString(_orgKey);
    await StorageRepository.deleteString(_driverIdKey);
    await StorageRepository.deleteBool(_routeReviewAvailableKey);
    // Back to optimistic: the next driver's entitlement is unknown, not false.
    _routeReviewNotifier.value = true;
  }

  static String _read(String storageKey, String envKey) {
    final stored = StorageRepository.getString(storageKey);
    if (stored.isNotEmpty) return stored;
    // dotenv throws if `load` hasn't run yet (e.g. a widget test that skips
    // setupLocator); an unconfigured session is the correct answer there.
    try {
      return dotenv.env[envKey] ?? '';
    } catch (_) {
      return '';
    }
  }
}

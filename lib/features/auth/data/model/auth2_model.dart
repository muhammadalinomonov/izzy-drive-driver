import 'package:taxi_app/core/utils/json_safe.dart';

/// Response models for the **second** login phase — `POST mobile/auth/login`
/// on the Quadrix Tolling backend (`docs/mobile-api.md` §2.1).
///
/// No request model here: [Auth2DataSource.logIn] takes the same `AuthModel`
/// [AuthRepo.logIn] does — one credential pair drives both backends by
/// delegation, so a second request type would just duplicate `email`/
/// `password` for no reason.
///
/// Deliberately separate from a hypothetical `AuthModel`-shaped response:
/// `api.izzydrive.com` returns a SimpleJWT `access`/`refresh` pair, this
/// backend returns a single Sanctum token that never refreshes. The two
/// sessions are independent — signing in to one says nothing about the other.

/// The `data` object of a successful login: the token plus everything needed
/// to pick the `X-Organization-Id` every protected endpoint requires.
///
/// The memberships arriving here are what makes the follow-up `GET auth/me`
/// lookup in `TollSession` unnecessary after a real sign-in — the org id is
/// already in this payload.
class Auth2Session {
  final Auth2User user;
  final List<Auth2Membership> memberships;
  final String token;
  final String tokenType;
  final List<String> abilities;

  const Auth2Session({
    required this.user,
    required this.memberships,
    required this.token,
    required this.tokenType,
    required this.abilities,
  });

  factory Auth2Session.fromJson(Map<String, dynamic> json) {
    return Auth2Session(
      user: Auth2User.fromJson(toMap(json['user'])),
      memberships: toList(
        json['memberships'],
        (e) => Auth2Membership.fromJson(toMap(e)),
      ),
      token: toStr(json['token']),
      tokenType: toStr(json['token_type'], 'Bearer'),
      abilities: toList(json['abilities'], (e) => toStr(e)),
    );
  }

  /// Organization id for the `X-Organization-Id` header.
  ///
  /// Same precedence rule as `TollSession._fetchOrganizationId`: an active
  /// driver membership wins, because a user can belong to several
  /// organizations and the `mobile/*` endpoints are driver-scoped. Falls back
  /// to the first membership that has an organization at all rather than
  /// failing outright. Empty when there is none — the caller then leaves the
  /// header off and the backend answers 400 ORGANIZATION_HEADER_REQUIRED.
  String get organizationId {
    for (final membership in memberships) {
      if (!membership.isActiveDriver) continue;
      if (membership.organization.id.isNotEmpty) {
        return membership.organization.id;
      }
    }
    for (final membership in memberships) {
      if (membership.organization.id.isNotEmpty) {
        return membership.organization.id;
      }
    }
    return '';
  }
}

class Auth2User {
  final String id;
  final String name;
  final String email;

  /// When true, every protected endpoint answers 403 PASSWORD_CHANGE_REQUIRED
  /// until the password is changed (docs §2.1) — the token is valid but
  /// useless, so the caller must branch on this before using the session.
  final bool mustChangePassword;

  const Auth2User({
    required this.id,
    required this.name,
    required this.email,
    required this.mustChangePassword,
  });

  factory Auth2User.fromJson(Map<String, dynamic> json) {
    return Auth2User(
      // Numeric on this backend, but read as a string so it survives a switch
      // to ULIDs like every other id in this API.
      id: toStr(json['id']),
      name: toStr(json['name']),
      email: toStr(json['email']),
      mustChangePassword: toBool(json['must_change_password']),
    );
  }
}

class Auth2Membership {
  final String id;
  final String role;

  /// Absent from the §2.1 sample response; treated as active when the backend
  /// omits it, since login only ever returns memberships that grant access.
  final String status;
  final Auth2Organization organization;

  const Auth2Membership({
    required this.id,
    required this.role,
    required this.status,
    required this.organization,
  });

  factory Auth2Membership.fromJson(Map<String, dynamic> json) {
    return Auth2Membership(
      id: toStr(json['id']),
      role: toStr(json['role']),
      status: toStr(json['status']),
      organization: Auth2Organization.fromJson(toMap(json['organization'])),
    );
  }

  bool get isActiveDriver {
    final normalizedStatus = status.toLowerCase();
    return role.toLowerCase() == 'driver' &&
        (normalizedStatus.isEmpty || normalizedStatus == 'active');
  }
}

class Auth2Organization {
  final String id;
  final String name;
  final String legalName;
  final String type;
  final String timezone;
  final String currency;
  final String status;

  const Auth2Organization({
    required this.id,
    required this.name,
    required this.legalName,
    required this.type,
    required this.timezone,
    required this.currency,
    required this.status,
  });

  factory Auth2Organization.fromJson(Map<String, dynamic> json) {
    return Auth2Organization(
      id: toStr(json['id']),
      name: toStr(json['name']),
      legalName: toStr(json['legal_name']),
      type: toStr(json['type']),
      timezone: toStr(json['timezone']),
      currency: toStr(json['currency']),
      status: toStr(json['status']),
    );
  }
}

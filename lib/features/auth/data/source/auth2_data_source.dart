import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:taxi_app/core/extensions/status_code_extension.dart';
import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/core/network/auth_session.dart';
import 'package:taxi_app/core/network/toll_api_constants.dart';
import 'package:taxi_app/core/network/toll_dio.dart';
import 'package:taxi_app/core/network/toll_session.dart';
import 'package:taxi_app/core/network/token_service.dart';
import 'package:taxi_app/core/service_locater.dart';
import 'package:taxi_app/core/utils/json_safe.dart';
import 'package:taxi_app/features/auth/data/model/auth2_model.dart';
import 'package:taxi_app/features/auth/data/model/auth_model.dart';

/// Sign-in against the Quadrix Tolling backend — the second login phase
/// (`docs/mobile-api.md` §2.1/§2.2).
///
/// Separate from [AuthDataSource], which owns the izzydrive session and must
/// keep working exactly as it does: different host, different token scheme,
/// different credentials. Neither one can stand in for the other.
@lazySingleton
class Auth2DataSource {
  Auth2DataSource();

  /// Authenticated calls go through the shared toll client so they pick up
  /// the bearer token and `X-Organization-Id` interceptor.
  final client = serviceLocator.get<TollDioSettings>().dio;

  /// `POST mobile/auth/login` — unauthenticated, and deliberately NOT sent
  /// through [client].
  ///
  /// That client's `onRequest` would attach whatever token is currently
  /// stored and then call `ensureOrganizationId`, firing `auth/me` with the
  /// *previous* user's credentials before we have replaced them. A bare Dio
  /// keeps a re-login (or a login after a stale token) from resolving the
  /// wrong organization.
  ///
  /// On success the token and organization id are persisted immediately, so
  /// every later toll-API call works without the caller doing anything.
  ///
  /// Takes the same [AuthModel] `AuthRepo.logIn` does - by delegation, one
  /// credential pair drives both backends, so there is no separate request
  /// type here. `AuthModel` carries no field for `device_name` (it has no
  /// counterpart on the izzydrive side), so it defaults to [_defaultDeviceName]
  /// rather than being left unset - the backend requires it.
  Future<NetworkResponse<Auth2Session>> logIn(AuthModel authModel) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: TollApiConstants.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    try {
      final response = await dio.post(
        TollApiConstants.login,
        data: {
          'email': authModel.email,
          'password': authModel.password,
          'device_name': _defaultDeviceName,
        },
      );
      if (!response.isSuccess) {
        return NetworkResponse<Auth2Session>(
          errorText: _errorMessage(response.data),
          errorCode: _errorCode(response.data),
        );
      }

      final session = Auth2Session.fromJson(toMap(toMap(response.data)['data']));
      if (session.token.isEmpty) {
        return NetworkResponse<Auth2Session>(
          errorText: 'Login response carried no token.',
          errorCode: 'TOLL_TOKEN_MISSING',
        );
      }
      await TollSession.saveSession(
        token: session.token,
        organizationId: session.organizationId,
      );
      await _mirrorPrimarySession(session);
      return NetworkResponse<Auth2Session>(data: session);
    } on DioException catch (e) {
      return NetworkResponse<Auth2Session>(
        errorText: _errorMessage(e.response?.data, 'Network error'),
        errorCode: _errorCode(e.response?.data),
      );
    } catch (e) {
      return NetworkResponse<Auth2Session>(errorText: e.toString());
    } finally {
      dio.close();
    }
  }

  /// `POST mobile/auth/logout` — revokes the current mobile token, no body.
  ///
  /// The local session is cleared either way: a failed revoke server-side
  /// still means this device is done with the token, and keeping it would
  /// only produce 401s.
  Future<NetworkResponse> logout() async {
    if (!TollSession.hasToken) {
      await TollSession.clear();
      await AuthSession.clear();
      return NetworkResponse();
    }
    try {
      final response = await client.post(TollApiConstants.logout);
      await TollSession.clear();
      await AuthSession.clear();
      if (response.isSuccess) {
        return NetworkResponse(data: response.data);
      }
      return NetworkResponse(
        errorText: _errorMessage(response.data),
        errorCode: _errorCode(response.data),
      );
    } on DioException catch (e) {
      await TollSession.clear();
      await AuthSession.clear();
      return NetworkResponse(
        errorText: _errorMessage(e.response?.data, 'Network error'),
        errorCode: _errorCode(e.response?.data),
      );
    } catch (e) {
      await TollSession.clear();
      await AuthSession.clear();
      return NetworkResponse(errorText: e.toString());
    }
  }

  /// Copies what a `mobile/auth/login` response has in common with an
  /// izzydrive login into the primary session keys, so an `auth2`-backed
  /// `AuthBloc` opens the same doors an `auth1` one does.
  ///
  /// Without this the app treats the driver as signed out no matter how well
  /// the toll login went: `AuthSession.isLoggedIn` reads `'token'`, and
  /// GoRouter's `redirect` bounces every protected route back to sign-in
  /// (`routes/app_router.dart`).
  ///
  /// The two payloads only partly line up, so the mapping is best-effort with
  /// one hard requirement - the token:
  ///
  /// | primary key      | auth2 source        | when absent                  |
  /// |------------------|---------------------|------------------------------|
  /// | `token`          | `data.token`        | never - caller checked it    |
  /// | `responseID`     | `data.user.id`      | left untouched               |
  /// | `refresh`        | (none)              | deleted - Sanctum can't refresh |
  /// | `phone_verified` | (none)              | deleted - re-resolved by get-me |
  ///
  /// `refresh` is deleted rather than left alone on purpose: a stale izzydrive
  /// refresh token paired with a toll access token would let the interceptor
  /// mint a session for the wrong user.
  static Future<void> _mirrorPrimarySession(Auth2Session session) async {
    await StorageRepository.putString('token', session.token);
    await StorageRepository.deleteString('refresh');
    if (session.user.id.isNotEmpty) {
      await StorageRepository.putString('responseID', session.user.id);
    }
    await StorageRepository.deleteBool('phone_verified');
    await AuthSession.setSource(AuthSession.sourceAuth2);
    // Let GoRouter re-run `redirect` now that the gate reads as signed in.
    AuthSession.notifyAuthChanged();
  }

  /// `AuthModel` has no `device_name` field to carry over, so login always
  /// sends this fixed label rather than leaving the required field unset.
  static const String _defaultDeviceName = 'Mobile device';

  /// Envelope shape is `{ "error": { "code": …, "message": … } }` on this
  /// backend, not the `{ "message": … }` the izzydrive API uses.
  static String _errorMessage(dynamic body, [String fallback = 'Server error']) {
    if (body is Map) {
      final error = body['error'];
      if (error is Map) {
        final message = error['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    }
    return dioErrorMessage(body, fallback);
  }

  static String? _errorCode(dynamic body) {
    if (body is! Map) return null;
    final error = body['error'];
    if (error is! Map) return null;
    final code = error['code'];
    return code is String && code.isNotEmpty ? code : null;
  }
}

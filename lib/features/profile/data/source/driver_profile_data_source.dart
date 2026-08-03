import 'package:dio/dio.dart';
import 'package:taxi_app/core/extensions/status_code_extension.dart';
import 'package:taxi_app/core/network/network_response.dart';
import 'package:taxi_app/core/network/toll_api_constants.dart';
import 'package:taxi_app/core/network/toll_dio.dart';
import 'package:taxi_app/core/network/toll_session.dart';
import 'package:taxi_app/core/service_locater.dart';
import 'package:taxi_app/core/utils/json_safe.dart';
import 'package:taxi_app/features/profile/data/model/driver_profile_model.dart';
import 'package:taxi_app/features/trips/data/model/vehicle_model.dart';

/// Quadrix Tolling driver profile and assigned vehicles (docs §3.2-§3.4).
///
/// Separate from [ProfileDataSource], which talks to the izzydrive backend.
/// The two hosts have different auth and different response envelopes, so they
/// deliberately do not share a client.
class DriverProfileDataSource {
  final client = serviceLocator.get<TollDioSettings>().dio;

  /// `GET mobile/profile`
  Future<NetworkResponse<DriverProfileModel>> fetchProfile() async {
    return _request(() => client.get(TollApiConstants.profile));
  }

  /// `PATCH mobile/profile` — partial update; only non-null fields are sent.
  ///
  /// PATCH, not POST, per the explicit warning in docs §3.3. Omitted fields
  /// are left untouched server-side, so this doubles as a single-field save.
  Future<NetworkResponse<DriverProfileModel>> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? licenseNumber,
    String? licenseState,
  }) async {
    final body = <String, dynamic>{
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (phone != null) 'phone': phone,
      if (licenseNumber != null) 'license_number': licenseNumber,
      if (licenseState != null) 'license_state': licenseState,
    };
    return _request(
      () => client.patch(TollApiConstants.profile, data: body),
    );
  }

  /// `GET mobile/vehicles` — trucks assigned to this driver.
  ///
  /// An empty `items` list is a normal response, not an error (§3.4).
  Future<NetworkResponse<List<VehicleModel>>> fetchVehicles() async {
    if (!TollSession.hasToken) {
      return NetworkResponse<List<VehicleModel>>(
        errorText: 'Toll account is not connected.',
        errorCode: 'TOLL_SESSION_MISSING',
      );
    }
    try {
      final response = await client.get(TollApiConstants.vehicles);
      if (response.isSuccess) {
        final data = toMap(toMap(response.data)['data']);
        return NetworkResponse<List<VehicleModel>>(
          data: toList(data['items'], (e) => VehicleModel.fromJson(toMap(e))),
        );
      }
      return NetworkResponse<List<VehicleModel>>(
        errorText: _errorMessage(response.data),
        errorCode: _errorCode(response.data),
      );
    } on DioException catch (e) {
      return NetworkResponse<List<VehicleModel>>(
        errorText: _errorMessage(e.response?.data, 'Network error'),
        errorCode: _errorCode(e.response?.data),
      );
    } catch (e) {
      return NetworkResponse<List<VehicleModel>>(errorText: e.toString());
    }
  }

  /// Shared envelope handling for the two profile calls, which return the same
  /// `DriverProfile` shape.
  Future<NetworkResponse<DriverProfileModel>> _request(
    Future<Response<dynamic>> Function() send,
  ) async {
    if (!TollSession.hasToken) {
      return NetworkResponse<DriverProfileModel>(
        errorText: 'Toll account is not connected.',
        errorCode: 'TOLL_SESSION_MISSING',
      );
    }
    try {
      final response = await send();
      if (response.isSuccess) {
        return NetworkResponse<DriverProfileModel>(
          data: DriverProfileModel.fromJson(
            toMap(toMap(response.data)['data']),
          ),
        );
      }
      return NetworkResponse<DriverProfileModel>(
        errorText: _errorMessage(response.data),
        errorCode: _errorCode(response.data),
      );
    } on DioException catch (e) {
      return NetworkResponse<DriverProfileModel>(
        errorText: _errorMessage(e.response?.data, 'Network error'),
        errorCode: _errorCode(e.response?.data),
      );
    } catch (e) {
      return NetworkResponse<DriverProfileModel>(errorText: e.toString());
    }
  }

  /// The toll API nests its message under `error`, unlike the izzydrive
  /// backend's flat `{detail}` / `{message}`.
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

import 'package:dio/dio.dart';
import 'package:taxi_app/src/core/extensions/status_code_extension.dart';
import 'package:taxi_app/src/core/network/api_constants.dart';
import 'package:taxi_app/src/core/network/dio_model.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/core/network/token_service.dart';
import 'package:taxi_app/src/core/service_locater.dart';
import '../model/profile_model.dart';

class ProfileDataSource {
  ProfileDataSource();

  final client = serviceLocator.get<DioSettings>().dio;

  Future<NetworkResponse> fetchProfile() async {
    try {
      final token = StorageRepository.getString('token');
      final response = await client.get(
        ApiConstants.profileGet,
        options: Options(headers: {'Authorization': "Bearer $token"}),
      );
      if (response.isSuccess) {
        print('Profile fetched successfully: ${response.data}');
        return NetworkResponse(data: ProfileModel.fromJson(response.data['data']));
      } else {
        print('Error fetching profile: ${response.data}');
        return NetworkResponse(
          errorText:
              response.data['message'] ?? 'Something went wrong try again',
        );
      }
    } on DioException catch (e) {
      print('Dio exception fetching profile: ${e.response?.statusCode}');
      print('Dio exception response body: ${e.response?.data}');
      return NetworkResponse(
        errorText: e.response?.data['message'] ?? 'Something went wrong',
      );
    } catch (e) {
      print('Error fetching profile: $e');
      return NetworkResponse(errorText: 'Something went wrong');
    }
  }
}

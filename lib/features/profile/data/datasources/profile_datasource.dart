import 'package:dio/dio.dart';

abstract class ProfileDataSource {
  Future<void> updateStatus({required bool isOnline});

  Future<void> updateCurrentLocation({
    required double latitude,
    required double longitude,
  });

}

class ProfileDataSourceImpl extends ProfileDataSource {
  final Dio dio;

  ProfileDataSourceImpl({required this.dio});

  @override
  Future<void> updateStatus({required bool isOnline}) async {
    try {
      final response = await dio.post(
        'mechanics/update-status/',
        data: {
          'status': isOnline ? 'online' : 'offline',
        },
      );
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return;
      } else {
        throw Exception('Failed to update status: ${response.data}');
      }
    } on DioException catch (e) {
      throw Exception('DioException: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> updateCurrentLocation({required double latitude, required double longitude}) async {
    try {
      final response = await dio.post(
        'mechanics/update-location/',
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return;
      } else {
        throw Exception('Failed to update location: ${response.data}');
      }
    } on DioException catch (e) {
      throw Exception('DioException: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }
}

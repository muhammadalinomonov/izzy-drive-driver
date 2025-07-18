import 'package:dio/dio.dart';
import '../model/profile_model.dart';

class ProfileDataSource {
  final Dio dio;
  ProfileDataSource(this.dio);

  Future<ProfileModel> fetchProfile() async {
    final response = await dio.get('/profile');
    return ProfileModel.fromJson(response.data);
  }
}

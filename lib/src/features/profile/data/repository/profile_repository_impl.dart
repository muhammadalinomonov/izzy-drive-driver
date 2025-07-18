import '../../domain/entities/profile_entity.dart';
import '../../domain/repository/profile_repository.dart';
import '../source/profile_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileDataSource dataSource;
  ProfileRepositoryImpl(this.dataSource);

  @override
  Future<ProfileEntity> getProfile() async {
    return await dataSource.fetchProfile();
  }
}

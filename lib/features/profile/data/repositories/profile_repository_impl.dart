import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<UserProfile> getUserProfileStream() {
    return remoteDataSource.getUserProfileStream();
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
  }
}

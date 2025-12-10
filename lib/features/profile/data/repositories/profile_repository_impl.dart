import '../../../../core/services/session_service.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final SessionService sessionService;

  ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.sessionService,
  });

  @override
  Stream<UserProfile> getUserProfileStream() async* {
    final user = await sessionService.getSession();
    if (user == null) throw Exception('User session not found');
    
    yield* remoteDataSource.getUserProfileStream(uid: user.uid);
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
    await sessionService.clearSession();
  }
}

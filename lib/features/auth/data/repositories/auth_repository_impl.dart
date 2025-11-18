import '../../domain/entities/user.dart' as entities;
import '../../domain/repositories/auth_repository.dart' as repositories;
import '../datasources/auth_remote_datasource.dart' as datasources;

class AuthRepositoryImpl implements repositories.AuthRepository {
  final datasources.AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<entities.User> login({required String nip, required String password}) {
    return remoteDataSource.login(nip: nip, password: password);
  }

  @override
  Future<entities.User> register({
    required String fullName,
    required String nip,
    required String password,
  }) {
    return remoteDataSource.register(
      fullName: fullName,
      nip: nip,
      password: password,
    );
  }

  @override
  Future<void> logout() {
    return remoteDataSource.logout();
  }

  @override
  Future<entities.User?> getCurrentUser() {
    return remoteDataSource.getCurrentUser();
  }

  @override
  Stream<entities.User?> get authStateChanges =>
      remoteDataSource.authStateChanges;
}

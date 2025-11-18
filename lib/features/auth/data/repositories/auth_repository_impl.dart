import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<User> login({required String nip, required String password}) {
    return remoteDataSource.login(nip: nip, password: password);
  }

  @override
  Future<User> register({
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
  Future<User?> getCurrentUser() {
    return remoteDataSource.getCurrentUser();
  }

  @override
  Stream<User?> get authStateChanges => remoteDataSource.authStateChanges;
}

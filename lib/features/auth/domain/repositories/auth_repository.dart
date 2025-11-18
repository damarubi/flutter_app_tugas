import '../entities/user.dart' as entities;

abstract class AuthRepository {
  Future<entities.User> login({required String nip, required String password});
  Future<entities.User> register({
    required String fullName,
    required String nip,
    required String password,
  });
  Future<void> logout();
  Future<entities.User?> getCurrentUser();
  Stream<entities.User?> get authStateChanges;
}

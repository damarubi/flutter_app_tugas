import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login({required String nip, required String password});
  Future<User> register({
    required String fullName,
    required String nip,
    required String password,
  });
  Future<void> logout();
  Future<User?> getCurrentUser();
  Stream<User?> get authStateChanges;
}

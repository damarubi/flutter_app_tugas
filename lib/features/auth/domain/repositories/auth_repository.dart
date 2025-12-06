import '../entities/user.dart';

abstract class AuthRepository {
  // Login dengan NIP
  Future<User> login({
    required String nip,
    required String password,
  });

  // Register dengan NIP
  Future<User> register({
    required String fullName,
    required String nip,
    required String password,
  });

  // Logout
  Future<void> logout();

  // Get Current User by UID
  Future<User?> getCurrentUser({String? uid});
}

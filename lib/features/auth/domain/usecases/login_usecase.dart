import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  /// Login dengan NIP dan password
  ///
  /// Input:
  ///   - nip: NIP pengguna
  ///   - password: password pengguna
  ///
  /// Output: User object jika login berhasil
  ///
  /// Exception: AuthException jika login gagal
  Future<User> call({
    required String nip,
    required String password,
  }) async {
    return await repository.login(
      nip: nip,
      password: password,
    );
  }
}

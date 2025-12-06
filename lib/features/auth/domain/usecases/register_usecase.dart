import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  /// Register dengan fullName, NIP, dan password
  ///
  /// Input:
  ///   - fullName: nama lengkap pengguna
  ///   - nip: NIP pengguna (unik)
  ///   - password: password pengguna
  ///
  /// Output: User object jika register berhasil
  ///
  /// Exception: AuthException jika:
  ///   - NIP sudah terdaftar
  ///   - Password terlalu lemah
  ///   - Terjadi error di Firestore
  ///
  /// Note: User otomatis login setelah register berhasil (session tersimpan)
  Future<User> call({
    required String fullName,
    required String nip,
    required String password,
  }) async {
    return await repository.register(
      fullName: fullName,
      nip: nip,
      password: password,
    );
  }
}

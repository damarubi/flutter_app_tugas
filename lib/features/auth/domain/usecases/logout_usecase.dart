import '../repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  /// Logout dari aplikasi
  ///
  /// Fungsi:
  ///   - Clear session dari local storage
  ///   - Clear data user yang tersimpan
  ///
  /// Exception: AuthException jika logout gagal
  Future<void> call() async {
    return await repository.logout();
  }
}

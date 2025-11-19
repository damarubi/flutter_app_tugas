import '../repositories/auth_repository.dart' as repositories;

class LogoutUseCase {
  final repositories.AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<void> call() {
    return repository.logout();
  }
}

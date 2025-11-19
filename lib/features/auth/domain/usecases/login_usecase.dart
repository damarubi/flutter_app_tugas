import '../entities/user.dart' as entities;
import '../repositories/auth_repository.dart' as repositories;

class LoginUseCase {
  final repositories.AuthRepository repository;

  LoginUseCase(this.repository);

  Future<entities.User> call({required String nip, required String password}) {
    return repository.login(nip: nip, password: password);
  }
}

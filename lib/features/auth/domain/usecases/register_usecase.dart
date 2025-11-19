import '../entities/user.dart' as entities;
import '../repositories/auth_repository.dart' as repositories;

class RegisterUseCase {
  final repositories.AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<entities.User> call({
    required String fullName,
    required String nip,
    required String password,
  }) {
    return repository.register(
      fullName: fullName,
      nip: nip,
      password: password,
    );
  }
}

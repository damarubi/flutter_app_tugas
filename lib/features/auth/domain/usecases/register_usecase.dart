import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<User> call({
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

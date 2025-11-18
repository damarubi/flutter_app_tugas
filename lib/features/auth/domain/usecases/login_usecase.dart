import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<User> call({required String nip, required String password}) {
    return repository.login(nip: nip, password: password);
  }
}

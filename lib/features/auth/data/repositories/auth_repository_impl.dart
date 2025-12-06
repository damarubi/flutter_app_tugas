import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart' as models;
import '../../../../core/errors/exceptions.dart' as exceptions;
import '../../../../core/services/session_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SessionService sessionService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.sessionService,
  });

  @override
  Future<models.UserModel> login({
    required String nip,
    required String password,
  }) async {
    try {
      // 1. Login ke Firestore
      final user = await remoteDataSource.login(
        nip: nip,
        password: password,
      );
      
      // 2. Simpan session ke local storage
      await sessionService.saveSession(user);
      
      return user;
    } on exceptions.AuthException {
      rethrow;
    } catch (e) {
      throw exceptions.AuthException('Gagal login: ${e.toString()}');
    }
  }

  @override
  Future<models.UserModel> register({
    required String fullName,
    required String nip,
    required String password,
  }) async {
    try {
      // 1. Register ke Firestore
      final user = await remoteDataSource.register(
        fullName: fullName,
        nip: nip,
        password: password,
      );
      
      // 2. Simpan session ke local storage (auto login setelah register)
      await sessionService.saveSession(user);
      
      return user;
    } on exceptions.AuthException {
      rethrow;
    } catch (e) {
      throw exceptions.AuthException('Gagal register: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      // 1. Call datasource logout (untuk cleanup)
      await remoteDataSource.logout();
      
      // 2. Clear session dari local storage
      await sessionService.clearSession();
    } on exceptions.AuthException {
      rethrow;
    } catch (e) {
      throw exceptions.AuthException('Gagal logout: ${e.toString()}');
    }
  }

  @override
  Future<models.UserModel?> getCurrentUser({String? uid}) async {
    try {
      return await remoteDataSource.getCurrentUser(uid: uid);
    } on exceptions.AuthException {
      rethrow;
    } catch (e) {
      throw exceptions.AuthException('Gagal get user: ${e.toString()}');
    }
  }
}
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../../../../core/errors/exceptions.dart' as exceptions;
import '../../../../core/services/password_service.dart';
import '../models/user_model.dart' as models;

abstract class AuthRemoteDataSource {
  Future<models.UserModel> login({
    required String nip,
    required String password,
  });
  Future<models.UserModel> register({
    required String fullName,
    required String nip,
    required String password,
  });
  Future<void> logout();
  Future<models.UserModel?> getCurrentUser({String? uid});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firestore.FirebaseFirestore firestoreInstance;

  AuthRemoteDataSourceImpl({
    required firestore.FirebaseFirestore firestore,
  }) : firestoreInstance = firestore;

  /// LOGIN dengan NIP dan password
  /// Flow:
  /// 1. Query Firestore untuk cari user by NIP
  /// 2. Jika tidak ketemu -> throw error
  /// 3. Jika ketemu -> verify password dengan hash
  /// 4. Jika password cocok -> return UserModel
  /// 5. Jika password tidak cocok -> throw error
  @override
  Future<models.UserModel> login({
    required String nip,
    required String password,
  }) async {
    try {
      // 1. Query user by NIP
      final querySnapshot = await firestoreInstance
          .collection('users')
          .where('nip', isEqualTo: nip)
          .limit(1)
          .get();

      // 2. Check apakah user ditemukan
      if (querySnapshot.docs.isEmpty) {
        throw exceptions.AuthException(
          'Pengguna tidak ditemukan untuk NIP: $nip',
        );
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();
      final passwordHash = userData['passwordHash'] as String?;

      // 3. Check apakah passwordHash ada
      if (passwordHash == null || passwordHash.isEmpty) {
        throw exceptions.AuthException(
          'Data password tidak valid. Silakan hubungi admin.',
        );
      }

      // 4. Verify password dengan hash
      final isPasswordValid = PasswordService.verifyPassword(
        password,
        passwordHash,
      );

      if (!isPasswordValid) {
        throw exceptions.AuthException('Password salah.');
      }

      // 5. Check apakah user aktif
      final isActive = userData['isActive'] as bool? ?? true;
      if (!isActive) {
        throw exceptions.AuthException(
          'Akun Anda telah dinonaktifkan. Hubungi admin.',
        );
      }

      // 6. Return UserModel jika semua valid
      return models.UserModel.fromFirestore(userDoc);
    } on exceptions.AuthException {
      rethrow;
    } catch (e) {
      throw exceptions.AuthException(
        'Terjadi kesalahan saat login. Silakan coba lagi: $e',
      );
    }
  }

  /// REGISTER dengan fullName, NIP, dan password
  /// Flow:
  /// 1. Validasi NIP belum terdaftar
  /// 2. Hash password
  /// 3. Generate UID baru (auto dari Firestore)
  /// 4. Simpan user ke Firestore dengan passwordHash
  /// 5. Return UserModel yang baru dibuat
  @override
  Future<models.UserModel> register({
    required String fullName,
    required String nip,
    required String password,
  }) async {
    try {
      // 1. Check apakah NIP sudah terdaftar
      final existingUser = await firestoreInstance
          .collection('users')
          .where('nip', isEqualTo: nip)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw exceptions.AuthException(
          'NIP sudah terdaftar. Silakan gunakan NIP lain atau login.',
        );
      }

      // 2. Hash password menggunakan bcrypt
      final passwordHash = PasswordService.hashPassword(password);

      // 3. Generate email dari NIP
      final email = '$nip@absensi.com';

      // 4. Buat UserModel baru
      final userModel = models.UserModel(
        uid: '', // UID akan di-generate oleh Firestore
        email: email,
        fullName: fullName,
        nip: nip,
        passwordHash: passwordHash, // Simpan hash, bukan plain password
        isActive: true, // Default aktif saat register
        role: 'user', // Default role adalah user
        createdAt: DateTime.now(),
      );

      // 5. Simpan ke Firestore (UID auto generate)
      final docRef = await firestoreInstance.collection('users').add(
            userModel.toFirestore(),
          );

      // 6. Return UserModel dengan UID yang sudah di-generate
      return models.UserModel(
        uid: docRef.id,
        email: email,
        fullName: fullName,
        nip: nip,
        passwordHash: passwordHash,
        isActive: true,
        role: 'user',
        createdAt: DateTime.now(),
      );
    } on exceptions.AuthException {
      rethrow;
    } catch (e) {
      throw exceptions.AuthException(
        'Terjadi kesalahan saat pendaftaran. Silakan coba lagi: $e',
      );
    }
  }

  /// LOGOUT
  /// Menghapus session dari SessionService (akan ditangani di repository/usecase)
  @override
  Future<void> logout() async {
    try {
      // Session service akan menghapus session di repository layer
      // Di sini kita tidak perlu firebase auth sign out
    } catch (e) {
      throw exceptions.AuthException('Gagal logout: ${e.toString()}');
    }
  }

  /// GET CURRENT USER dari Firestore by UID
  /// Parameter uid: dari session local storage
  @override
  Future<models.UserModel?> getCurrentUser({String? uid}) async {
    try {
      if (uid == null || uid.isEmpty) {
        return null;
      }

      final doc = await firestoreInstance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        return null;
      }

      return models.UserModel.fromFirestore(doc);
    } catch (e) {
      throw exceptions.AuthException(
        'Gagal mendapatkan data user: ${e.toString()}',
      );
    }
  }
}
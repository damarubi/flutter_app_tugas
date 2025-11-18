import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String nip, required String password});
  Future<UserModel> register({
    required String fullName,
    required String nip,
    required String password,
  });
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Future<UserModel> login({
    required String nip,
    required String password,
  }) async {
    try {
      final email = '$nip@absensi.com';
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw AuthException('Login gagal');
      }

      final doc = await firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!doc.exists) {
        throw AuthException('Data pengguna tidak ditemukan');
      }

      return UserModel.fromFirestore(doc);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw AuthException('Pengguna tidak ditemukan untuk NIP tersebut.');
      } else if (e.code == 'wrong-password') {
        throw AuthException('Password salah.');
      } else {
        throw AuthException('Terjadi kesalahan. Silakan coba lagi.');
      }
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<UserModel> register({
    required String fullName,
    required String nip,
    required String password,
  }) async {
    try {
      final email = '$nip@absensi.com';
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw AuthException('Pendaftaran gagal');
      }

      final userModel = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        fullName: fullName,
        nip: nip,
        createdAt: DateTime.now(),
      );

      await firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userModel.toFirestore());

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw AuthException('Password terlalu lemah.');
      } else if (e.code == 'email-already-in-use') {
        throw AuthException('Akun sudah terdaftar untuk NIP ini.');
      } else {
        throw AuthException(
          'Terjadi kesalahan saat pendaftaran. Silakan coba lagi.',
        );
      }
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await firebaseAuth.signOut();
    } catch (e) {
      throw AuthException('Gagal logout: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = firebaseAuth.currentUser;
      if (firebaseUser == null) return null;

      final doc = await firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (!doc.exists) return null;

      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw AuthException('Gagal mendapatkan user: ${e.toString()}');
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      final doc = await firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (!doc.exists) return null;

      return UserModel.fromFirestore(doc);
    });
  }
}

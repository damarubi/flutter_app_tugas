import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../../../../core/errors/exceptions.dart' as exceptions;
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
  Future<models.UserModel?> getCurrentUser();
  Stream<models.UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;
  final firestore.FirebaseFirestore firestoreInstance;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required firestore.FirebaseFirestore firestore,
  }) : firestoreInstance = firestore;

  @override
  Future<models.UserModel> login({
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
        throw exceptions.AuthException('Login gagal');
      }

      final doc = await firestoreInstance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!doc.exists) {
        throw exceptions.AuthException('Data pengguna tidak ditemukan');
      }

      return models.UserModel.fromFirestore(doc);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw exceptions.AuthException(
          'Pengguna tidak ditemukan untuk NIP tersebut.',
        );
      } else if (e.code == 'wrong-password') {
        throw exceptions.AuthException('Password salah.');
      } else {
        throw exceptions.AuthException('Terjadi kesalahan. Silakan coba lagi.');
      }
    } catch (e) {
      throw exceptions.AuthException(e.toString());
    }
  }

  @override
  Future<models.UserModel> register({
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
        throw exceptions.AuthException('Pendaftaran gagal');
      }

      final userModel = models.UserModel(
        uid: userCredential.user!.uid,
        email: email,
        fullName: fullName,
        nip: nip,
        createdAt: DateTime.now(),
      );

      await firestoreInstance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userModel.toFirestore());

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw exceptions.AuthException('Password terlalu lemah.');
      } else if (e.code == 'email-already-in-use') {
        throw exceptions.AuthException('Akun sudah terdaftar untuk NIP ini.');
      } else {
        throw exceptions.AuthException(
          'Terjadi kesalahan saat pendaftaran. Silakan coba lagi.',
        );
      }
    } catch (e) {
      throw exceptions.AuthException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await firebaseAuth.signOut();
    } catch (e) {
      throw exceptions.AuthException('Gagal logout: ${e.toString()}');
    }
  }

  @override
  Future<models.UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = firebaseAuth.currentUser;
      if (firebaseUser == null) return null;

      final doc = await firestoreInstance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (!doc.exists) return null;

      return models.UserModel.fromFirestore(doc);
    } catch (e) {
      throw exceptions.AuthException('Gagal mendapatkan user: ${e.toString()}');
    }
  }

  @override
  Stream<models.UserModel?> get authStateChanges {
    return firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      final doc = await firestoreInstance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (!doc.exists) return null;

      return models.UserModel.fromFirestore(doc);
    });
  }
}

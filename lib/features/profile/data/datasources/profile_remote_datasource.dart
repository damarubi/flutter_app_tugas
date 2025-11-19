import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Stream<UserProfileModel> getUserProfileStream();
  Future<void> logout();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  ProfileRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Stream<UserProfileModel> getUserProfileStream() {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return firestore.collection('users').doc(user.uid).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) {
        throw Exception('User profile not found');
      }

      final data = snapshot.data()!;
      return UserProfileModel.fromFirestore(user.uid, data);
    });
  }

  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Stream<UserProfileModel> getUserProfileStream({required String uid});
  Future<void> logout();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseFirestore firestore;

  ProfileRemoteDataSourceImpl({
    required this.firestore,
  });

  @override
  Stream<UserProfileModel> getUserProfileStream({required String uid}) {
    return firestore.collection('users').doc(uid).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) {
        throw Exception('User profile not found');
      }

      final data = snapshot.data()!;
      return UserProfileModel.fromFirestore(uid, data);
    });
  }

  @override
  Future<void> logout() async {
    // Logout handled by AuthRepository
  }
}

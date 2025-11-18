import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../../domain/entities/user.dart' as entities;

class UserModel extends entities.User {
  const UserModel({
    required super.uid,
    required super.email,
    required super.fullName,
    required super.nip,
    super.createdAt,
    super.faceDataBase64,
  });

  factory UserModel.fromFirestore(firestore.DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      nip: data['nip'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as firestore.Timestamp).toDate()
          : null,
      faceDataBase64: data['faceDataBase64'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'fullName': fullName,
      'nip': nip,
      'createdAt': createdAt != null
          ? firestore.Timestamp.fromDate(createdAt!)
          : firestore.FieldValue.serverTimestamp(),
      if (faceDataBase64 != null) 'faceDataBase64': faceDataBase64,
    };
  }

  factory UserModel.fromEntity(entities.User user) {
    return UserModel(
      uid: user.uid,
      email: user.email,
      fullName: user.fullName,
      nip: user.nip,
      createdAt: user.createdAt,
      faceDataBase64: user.faceDataBase64,
    );
  }
}

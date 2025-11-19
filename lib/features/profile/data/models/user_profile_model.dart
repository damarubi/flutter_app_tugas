import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  UserProfileModel({
    required super.uid,
    required super.fullName,
    required super.nip,
    required super.email,
    super.faceDataBase64,
    super.isActive,
  });

  factory UserProfileModel.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    return UserProfileModel(
      uid: uid,
      fullName: data['fullName'] ?? '',
      nip: data['nip'] ?? '',
      email: data['email'] ?? '',
      faceDataBase64: data['faceDataBase64'],
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'nip': nip,
      'email': email,
      'faceDataBase64': faceDataBase64,
      'isActive': isActive,
    };
  }
}

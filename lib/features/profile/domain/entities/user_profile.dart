class UserProfile {
  final String uid;
  final String fullName;
  final String nip;
  final String email;
  final String? faceDataBase64;
  final bool isActive;

  UserProfile({
    required this.uid,
    required this.fullName,
    required this.nip,
    required this.email,
    this.faceDataBase64,
    this.isActive = true,
  });

  String get statusLabel => isActive ? 'Aktif' : 'Tidak Aktif';
}

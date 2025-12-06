class User {
  final String uid;
  final String email;
  final String fullName;
  final String nip;
  final String? passwordHash;
  final bool isActive;
  final String role;
  final DateTime? createdAt;
  final String? faceDataBase64;

  const User({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.nip,
    this.passwordHash,
    this.isActive = true,
    this.role = 'user',
    this.createdAt,
    this.faceDataBase64,
  });
}

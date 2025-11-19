class User {
  final String uid;
  final String email;
  final String fullName;
  final String nip;
  final DateTime? createdAt;
  final String? faceDataBase64;

  const User({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.nip,
    this.createdAt,
    this.faceDataBase64,
  });
}

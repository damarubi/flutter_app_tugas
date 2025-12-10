import 'package:bcrypt/bcrypt.dart';

class PasswordService {
  /// Hash password dengan bcrypt
  /// Input: plainPassword - password plain text dari user
  /// Output: hash password yang aman untuk disimpan di Firestore
  /// 
  /// Contoh:
  /// Input: "MyPassword123"
  /// Output: "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcg7b3XeKeUxWdeS86E36XQfPqm"
  static String hashPassword(String plainPassword) {
    try {
      return BCrypt.hashpw(plainPassword, BCrypt.gensalt());
    } catch (e) {
      throw Exception('Failed to hash password: $e');
    }
  }

  /// Verifikasi password dengan membandingkan plain text dengan hash
  /// 
  /// Input: 
  ///   - plainPassword: password yang diinput user saat login
  ///   - hash: passwordHash dari Firestore
  /// 
  /// Output: 
  ///   - true jika password cocok
  ///   - false jika password tidak cocok
  /// 
  /// Contoh:
  /// plainPassword: "MyPassword123"
  /// hash: "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcg7b3XeKeUxWdeS86E36XQfPqm"
  /// Result: true (cocok)
  static bool verifyPassword(String plainPassword, String hash) {
    try {
      return BCrypt.checkpw(plainPassword, hash);
    } catch (e) {
      throw Exception('Failed to verify password: $e');
    }
  }
}
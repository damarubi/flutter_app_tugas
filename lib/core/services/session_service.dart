import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../features/auth/data/models/user_model.dart';

class SessionService {
  static const String _sessionKey = 'user_session';
  SharedPreferences? _prefs;

  // Singleton pattern untuk mencegah multiple instances
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  static SessionService get instance => _instance;

  SessionService._internal();

  /// Initialize SessionService
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Helper untuk memastikan prefs sudah terinisialisasi
  Future<SharedPreferences> get _getPrefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Simpan user session ke local storage (SharedPreferences)
  Future<void> saveSession(UserModel user) async {
    try {
      final prefs = await _getPrefs;
      final userJson = {
        'uid': user.uid,
        'email': user.email,
        'fullName': user.fullName,
        'nip': user.nip,
        'isActive': user.isActive,
        'role': user.role,
      };

      final jsonString = jsonEncode(userJson);
      await prefs.setString(_sessionKey, jsonString);
    } catch (e) {
      throw Exception('Failed to save session: $e');
    }
  }

  /// Ambil user session dari local storage
  Future<UserModel?> getSession() async {
    try {
      final prefs = await _getPrefs;
      final jsonString = prefs.getString(_sessionKey);

      if (jsonString == null) {
        return null;
      }

      final userJson = jsonDecode(jsonString) as Map<String, dynamic>;

      return UserModel(
        uid: userJson['uid'] ?? '',
        email: userJson['email'] ?? '',
        fullName: userJson['fullName'] ?? '',
        nip: userJson['nip'] ?? '',
        isActive: userJson['isActive'] ?? true,
        role: userJson['role'] ?? 'user',
      );
    } catch (e) {
      throw Exception('Failed to get session: $e');
    }
  }

  /// Hapus user session dari local storage
  Future<void> clearSession() async {
    try {
      final prefs = await _getPrefs;
      await prefs.remove(_sessionKey);
    } catch (e) {
      throw Exception('Failed to clear session: $e');
    }
  }

  /// Check apakah user sudah login
  Future<bool> isSessionExists() async {
    try {
      final prefs = await _getPrefs;
      final jsonString = prefs.getString(_sessionKey);
      return jsonString != null;
    } catch (e) {
      return false;
    }
  }
}

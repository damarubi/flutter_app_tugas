import '../entities/user_profile.dart';

abstract class ProfileRepository {
  Stream<UserProfile> getUserProfileStream();
  Future<void> logout();
}

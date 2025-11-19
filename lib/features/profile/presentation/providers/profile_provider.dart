import 'package:flutter/material.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/get_user_profile_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';

class ProfileProvider extends ChangeNotifier {
  final GetUserProfileUseCase getUserProfileUseCase;
  final LogoutUseCase logoutUseCase;

  ProfileProvider({
    required this.getUserProfileUseCase,
    required this.logoutUseCase,
  });

  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Stream<UserProfile> getUserProfileStream() {
    return getUserProfileUseCase.call();
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await logoutUseCase.call();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}

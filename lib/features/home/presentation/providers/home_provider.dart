import 'package:flutter/foundation.dart';
import '../../domain/entities/dashboard.dart' as entities;
import '../../domain/usecases/get_dashboard_data_usecase.dart' as usecases;

class HomeProvider extends ChangeNotifier {
  final usecases.GetDashboardDataUseCase getDashboardDataUseCase;

  HomeProvider({required this.getDashboardDataUseCase});

  entities.Dashboard? _dashboard;
  bool _isLoading = false;
  String? _errorMessage;

  entities.Dashboard? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboard = await getDashboardDataUseCase();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _dashboard = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadDashboardData();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

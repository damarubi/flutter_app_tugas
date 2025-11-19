import '../entities/dashboard.dart' as entities;

abstract class HomeRepository {
  Future<entities.Dashboard> getDashboardData();
}

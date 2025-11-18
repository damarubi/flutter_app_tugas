import '../repositories/home_repository.dart' as repositories;
import '../entities/dashboard.dart' as entities;

class GetDashboardDataUseCase {
  final repositories.HomeRepository repository;

  GetDashboardDataUseCase(this.repository);

  Future<entities.Dashboard> call() async {
    return await repository.getDashboardData();
  }
}

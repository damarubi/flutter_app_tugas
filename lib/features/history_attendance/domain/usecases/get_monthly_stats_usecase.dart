import '../repositories/history_repository.dart';

class GetMonthlyStatsUseCase {
  final HistoryRepository repository;

  GetMonthlyStatsUseCase(this.repository);

  Future<Map<String, int>> call(int year, int month) {
    return repository.getMonthlyStats(year, month);
  }
}

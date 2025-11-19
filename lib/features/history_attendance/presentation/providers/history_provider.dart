import 'package:flutter/foundation.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/usecases/get_attendance_history_usecase.dart';
import '../../domain/usecases/get_monthly_stats_usecase.dart';

class HistoryProvider extends ChangeNotifier {
  final GetAttendanceHistoryUseCase getAttendanceHistoryUseCase;
  final GetMonthlyStatsUseCase getMonthlyStatsUseCase;

  HistoryProvider({
    required this.getAttendanceHistoryUseCase,
    required this.getMonthlyStatsUseCase,
  });

  DateTime _selectedDate = DateTime.now();
  Map<String, int> _stats = {'hadir': 0, 'tidakHadir': 0};
  bool _isLoadingStats = false;

  DateTime get selectedDate => _selectedDate;
  Map<String, int> get stats => _stats;
  bool get isLoadingStats => _isLoadingStats;

  Stream<List<AttendanceRecord>> getAttendanceHistoryStream() {
    return getAttendanceHistoryUseCase(
      _selectedDate.year,
      _selectedDate.month,
    );
  }

  Future<void> loadMonthlyStats() async {
    _isLoadingStats = true;
    notifyListeners();

    try {
      _stats = await getMonthlyStatsUseCase(
        _selectedDate.year,
        _selectedDate.month,
      );
    } catch (e) {
      debugPrint('Error loading stats: $e');
      _stats = {'hadir': 0, 'tidakHadir': 0};
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  void changeMonth(int year, int month) {
    _selectedDate = DateTime(year, month);
    notifyListeners();
    loadMonthlyStats();
  }

  void nextMonth() {
    final nextDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    changeMonth(nextDate.year, nextDate.month);
  }

  void previousMonth() {
    final prevDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    changeMonth(prevDate.year, prevDate.month);
  }
}

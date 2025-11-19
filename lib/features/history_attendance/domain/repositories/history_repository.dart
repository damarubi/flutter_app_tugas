import '../entities/attendance_record.dart';

abstract class HistoryRepository {
  Stream<List<AttendanceRecord>> getAttendanceHistory(int year, int month);
  Future<Map<String, int>> getMonthlyStats(int year, int month);
}

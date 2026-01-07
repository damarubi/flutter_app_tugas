import '../entities/attendance.dart' as entities;
import '../entities/attendance_status.dart' as entities;

abstract class AttendanceRepository {
  Future<entities.AttendanceStatus> checkAttendanceStatus();
  Future<void> recordAttendance({required String type});
  Future<List<entities.Attendance>> getAttendanceHistory();
  Future<Map<String, dynamic>?> getTodayAttendance();
}

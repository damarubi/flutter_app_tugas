import '../entities/attendance.dart' as entities;
import '../repositories/attendance_repository.dart' as repositories;

class GetAttendanceHistoryUseCase {
  final repositories.AttendanceRepository repository;

  GetAttendanceHistoryUseCase(this.repository);

  Future<List<entities.Attendance>> call() async {
    return await repository.getAttendanceHistory();
  }
}

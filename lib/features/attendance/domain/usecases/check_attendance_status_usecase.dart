import '../entities/attendance_status.dart' as entities;
import '../repositories/attendance_repository.dart' as repositories;

class CheckAttendanceStatusUseCase {
  final repositories.AttendanceRepository repository;

  CheckAttendanceStatusUseCase(this.repository);

  Future<entities.AttendanceStatus> call() async {
    return await repository.checkAttendanceStatus();
  }
}

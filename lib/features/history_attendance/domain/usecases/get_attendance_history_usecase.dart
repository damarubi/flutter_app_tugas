import '../entities/attendance_record.dart';
import '../repositories/history_repository.dart';

class GetAttendanceHistoryUseCase {
  final HistoryRepository repository;

  GetAttendanceHistoryUseCase(this.repository);

  Stream<List<AttendanceRecord>> call(int year, int month) {
    return repository.getAttendanceHistory(year, month);
  }
}

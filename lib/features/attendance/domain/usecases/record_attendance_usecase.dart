import '../repositories/attendance_repository.dart' as repositories;

class RecordAttendanceUseCase {
  final repositories.AttendanceRepository repository;

  RecordAttendanceUseCase(this.repository);

  Future<void> call({required String type}) async {
    // Validasi type
    if (type != 'Masuk' && type != 'Keluar') {
      throw Exception('Invalid attendance type: $type');
    }

    return await repository.recordAttendance(type: type);
  }
}

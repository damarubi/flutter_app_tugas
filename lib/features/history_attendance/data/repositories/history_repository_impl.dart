import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_remote_datasource.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryRemoteDataSource remoteDataSource;

  HistoryRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<AttendanceRecord>> getAttendanceHistory(int year, int month) {
    return remoteDataSource.getAttendanceHistory(year, month);
  }

  @override
  Future<Map<String, int>> getMonthlyStats(int year, int month) {
    return remoteDataSource.getMonthlyStats(year, month);
  }
}

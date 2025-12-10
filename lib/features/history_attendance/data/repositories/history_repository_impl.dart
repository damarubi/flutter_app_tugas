import '../../../../core/services/session_service.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_remote_datasource.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryRemoteDataSource remoteDataSource;
  final SessionService sessionService;

  HistoryRepositoryImpl({
    required this.remoteDataSource,
    required this.sessionService,
  });

  @override
  Stream<List<AttendanceRecord>> getAttendanceHistory(int year, int month) async* {
    final user = await sessionService.getSession();
    if (user != null) {
      yield* remoteDataSource.getAttendanceHistory(user.uid, year, month);
    } else {
      yield [];
    }
  }

  @override
  Future<Map<String, int>> getMonthlyStats(int year, int month) async {
    final user = await sessionService.getSession();
    if (user == null) return {'hadir': 0, 'tidakHadir': 0};
    return remoteDataSource.getMonthlyStats(user.uid, year, month);
  }
}

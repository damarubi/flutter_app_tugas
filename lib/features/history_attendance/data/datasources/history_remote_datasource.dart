import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_record_model.dart';

abstract class HistoryRemoteDataSource {
  Stream<List<AttendanceRecordModel>> getAttendanceHistory(
    String uid,
    int year,
    int month,
  );
  Future<Map<String, int>> getMonthlyStats(String uid, int year, int month);
}

class HistoryRemoteDataSourceImpl implements HistoryRemoteDataSource {
  final FirebaseFirestore firestore;

  HistoryRemoteDataSourceImpl({
    required this.firestore,
  });

  @override
  Stream<List<AttendanceRecordModel>> getAttendanceHistory(
    String uid,
    int year,
    int month,
  ) {
    // Start and end of month
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    return firestore
        .collection('users')
        .doc(uid)
        .collection('attendance')
        .snapshots()
        .map((snapshot) {
          // Convert each doc to list of records (can have both Masuk and Keluar)
          final allRecords = <AttendanceRecordModel>[];
          for (var doc in snapshot.docs) {
            allRecords.addAll(AttendanceRecordModel.fromFirestoreDoc(doc));
          }

          // Filter by date in memory to avoid composite index
          final records = allRecords.where((record) {
            return record.timestamp.isAfter(
                  startDate.subtract(const Duration(seconds: 1)),
                ) &&
                record.timestamp.isBefore(
                  endDate.add(const Duration(seconds: 1)),
                );
          }).toList();

          // Sort by timestamp descending
          records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return records;
        });
  }

  @override
  Future<Map<String, int>> getMonthlyStats(
    String uid,
    int year,
    int month,
  ) async {
    final now = DateTime.now();
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('attendance')
        .get();

    // Filter by date and count unique days with Masuk records
    final uniqueDays = <int>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();

      // Get timestamp
      DateTime? timestamp;
      if (data['timestamp'] != null) {
        timestamp = (data['timestamp'] as Timestamp).toDate();
      }

      if (timestamp != null) {
        // Check if in current month
        if (timestamp.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            timestamp.isBefore(endDate.add(const Duration(seconds: 1)))) {
          // Check if has MasukTime
          if (data.containsKey('MasukTime') && data['MasukTime'] != null) {
            uniqueDays.add(timestamp.day);
          }
        }
      }
    }

    // Calculate days that have passed (only count up to current date)
    final isCurrentMonth = year == now.year && month == now.month;
    final lastDayToCount = isCurrentMonth
        ? now.day
        : DateTime(year, month + 1, 0).day;

    final hadir = uniqueDays.length;
    final tidakHadir = lastDayToCount - hadir;

    return {'hadir': hadir, 'tidakHadir': tidakHadir};
  }
}

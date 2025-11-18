import '../../domain/entities/dashboard.dart' as entities;

class DashboardModel extends entities.Dashboard {
  DashboardModel({
    required super.userName,
    required super.userNip,
    super.userPhotoUrl,
    super.distanceFromOffice,
    required super.isInOfficeArea,
    required super.hasTodayAttendance,
    super.todayCheckIn,
    super.todayCheckOut,
    required super.totalAttendanceThisMonth,
  });

  factory DashboardModel.fromFirestore({
    required Map<String, dynamic> userData,
    required Map<String, dynamic>? attendanceData,
    required int monthlyCount,
    required double? distance,
    required bool inOfficeArea,
  }) {
    return DashboardModel(
      userName: userData['name'] ?? 'User',
      userNip: userData['nip'] ?? '-',
      userPhotoUrl: userData['photoUrl'],
      distanceFromOffice: distance,
      isInOfficeArea: inOfficeArea,
      hasTodayAttendance: attendanceData != null,
      todayCheckIn: attendanceData?['MasukTime'] != null
          ? _parseTime(attendanceData!['tanggal'], attendanceData['MasukTime'])
          : null,
      todayCheckOut: attendanceData?['KeluarTime'] != null
          ? _parseTime(attendanceData!['tanggal'], attendanceData['KeluarTime'])
          : null,
      totalAttendanceThisMonth: monthlyCount,
    );
  }

  static DateTime? _parseTime(String date, String time) {
    try {
      return DateTime.parse('$date $time');
    } catch (e) {
      return null;
    }
  }
}

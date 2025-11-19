class Dashboard {
  final String userName;
  final String userNip;
  final String? userPhotoUrl;
  final double? distanceFromOffice;
  final bool isInOfficeArea;
  final bool hasTodayAttendance;
  final DateTime? todayCheckIn;
  final DateTime? todayCheckOut;
  final int totalAttendanceThisMonth;

  Dashboard({
    required this.userName,
    required this.userNip,
    this.userPhotoUrl,
    this.distanceFromOffice,
    required this.isInOfficeArea,
    required this.hasTodayAttendance,
    this.todayCheckIn,
    this.todayCheckOut,
    required this.totalAttendanceThisMonth,
  });

  String get greetingMessage {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  String get distanceMessage {
    if (distanceFromOffice == null) return 'Mengecek lokasi...';
    final distance = distanceFromOffice ?? 0;
    if (distance <= 100) {
      return 'Anda berada di area kantor';
    }
    return '${distance.toStringAsFixed(0)} meter dari kantor';
  }

  String get attendanceStatus {
    if (hasTodayAttendance) {
      if (todayCheckIn != null && todayCheckOut == null) {
        return 'Sudah Check-in';
      } else if (todayCheckIn != null && todayCheckOut != null) {
        return 'Sudah Check-out';
      }
    }
    return 'Belum Absen';
  }
}

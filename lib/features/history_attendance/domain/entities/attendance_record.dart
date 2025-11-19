class AttendanceRecord {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String type; // 'clock_in' or 'clock_out'
  final String location;
  final double latitude;
  final double longitude;

  AttendanceRecord({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.type,
    required this.location,
    required this.latitude,
    required this.longitude,
  });

  bool get isClockIn => type == 'Masuk' || type == 'clock_in';
  bool get isClockOut => type == 'Keluar' || type == 'clock_out';
}

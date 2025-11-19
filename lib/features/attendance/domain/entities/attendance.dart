class Attendance {
  final String id;
  final String userId;
  final String email;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final double latitude;
  final double longitude;

  Attendance({
    required this.id,
    required this.userId,
    required this.email,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.latitude,
    required this.longitude,
  });

  bool get hasCheckedIn => checkInTime != null;
  bool get hasCheckedOut => checkOutTime != null;
}

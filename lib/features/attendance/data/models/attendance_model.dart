import '../../domain/entities/attendance.dart' as entities;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

class AttendanceModel extends entities.Attendance {
  AttendanceModel({
    required super.id,
    required super.userId,
    required super.email,
    required super.date,
    super.checkInTime,
    super.checkOutTime,
    required super.latitude,
    required super.longitude,
  });

  factory AttendanceModel.fromJson(
    Map<String, dynamic> json,
    String documentId,
  ) {
    return AttendanceModel(
      id: documentId,
      userId: json['userId'] ?? '',
      email: json['email'] ?? '',
      date: (json['tanggal'] as String).isNotEmpty
          ? DateTime.parse(json['tanggal'])
          : DateTime.now(),
      checkInTime: json['MasukTime'] != null
          ? _parseTime(json['tanggal'], json['MasukTime'])
          : null,
      checkOutTime: json['KeluarTime'] != null
          ? _parseTime(json['tanggal'], json['KeluarTime'])
          : null,
      latitude: (json['lat'] ?? 0.0).toDouble(),
      longitude: (json['long'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'tanggal': AttendanceModel.formatDate(date),
      'timestamp': firestore.FieldValue.serverTimestamp(),
      'lat': latitude,
      'long': longitude,
      if (checkInTime != null)
        'MasukTime': AttendanceModel.formatTime(checkInTime!),
      if (checkOutTime != null)
        'KeluarTime': AttendanceModel.formatTime(checkOutTime!),
    };
  }

  static DateTime? _parseTime(String dateStr, String timeStr) {
    try {
      final dateParts = dateStr.split('-');
      final timeParts = timeStr.split(':');
      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.parse(timeParts[2]),
      );
    } catch (e) {
      return null;
    }
  }

  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}

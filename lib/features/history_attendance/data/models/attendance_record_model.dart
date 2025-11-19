import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/attendance_record.dart';

class AttendanceRecordModel extends AttendanceRecord {
  AttendanceRecordModel({
    required super.id,
    required super.userId,
    required super.timestamp,
    required super.type,
    required super.location,
    required super.latitude,
    required super.longitude,
  });

  factory AttendanceRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Determine type based on which fields exist
    String type = '';
    if (data.containsKey('MasukTime') && data['MasukTime'] != null) {
      type = 'Masuk';
    } else if (data.containsKey('KeluarTime') && data['KeluarTime'] != null) {
      type = 'Keluar';
    }

    // Get timestamp
    DateTime timestamp;
    if (data['timestamp'] != null) {
      timestamp = (data['timestamp'] as Timestamp).toDate();
    } else {
      timestamp = DateTime.now();
    }

    return AttendanceRecordModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      timestamp: timestamp,
      type: type,
      location: '', // Location not stored in current structure
      latitude: data['lat']?.toDouble() ?? 0.0,
      longitude: data['long']?.toDouble() ?? 0.0,
    );
  }

  // Create list of records from a single Firestore document
  // (one document can have both Masuk and Keluar)
  static List<AttendanceRecordModel> fromFirestoreDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final records = <AttendanceRecordModel>[];

    // Get timestamp
    DateTime timestamp;
    if (data['timestamp'] != null) {
      timestamp = (data['timestamp'] as Timestamp).toDate();
    } else {
      timestamp = DateTime.now();
    }

    final userId = data['userId'] ?? '';
    final lat = data['lat']?.toDouble() ?? 0.0;
    final long = data['long']?.toDouble() ?? 0.0;

    // Create Masuk record if exists
    if (data.containsKey('MasukTime') && data['MasukTime'] != null) {
      records.add(
        AttendanceRecordModel(
          id: '${doc.id}_masuk',
          userId: userId,
          timestamp: timestamp,
          type: 'Masuk',
          location: '',
          latitude: lat,
          longitude: long,
        ),
      );
    }

    // Create Keluar record if exists
    if (data.containsKey('KeluarTime') && data['KeluarTime'] != null) {
      records.add(
        AttendanceRecordModel(
          id: '${doc.id}_keluar',
          userId: userId,
          timestamp: timestamp,
          type: 'Keluar',
          location: '',
          latitude: lat,
          longitude: long,
        ),
      );
    }

    return records;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:geolocator/geolocator.dart' as geolocator;
import '../models/attendance_model.dart' as models;
import '../../../../core/errors/exceptions.dart' as exceptions;
import '../../../../shared/services/location_service.dart' as services;
import '../../../../core/constants/app_constants.dart' as constants;
import '../../../../core/services/office_location_service.dart';

abstract class AttendanceRemoteDataSource {
  Future<Map<String, dynamic>> checkAttendanceStatus({required String uid});
  Future<void> recordAttendance({
    required String uid,
    required String email,
    required String type,
  });
  Future<List<models.AttendanceModel>> getAttendanceHistory({
    required String uid,
  });
  Future<Map<String, dynamic>?> getTodayAttendance({required String uid});
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final firestore.FirebaseFirestore firestoreInstance;
  final services.LocationService locationService;
  final OfficeLocationService officeLocationService;

  AttendanceRemoteDataSourceImpl({
    required firestore.FirebaseFirestore firestore,
    required this.locationService,
    OfficeLocationService? officeLocationService,
  }) : firestoreInstance = firestore,
       officeLocationService = officeLocationService ?? OfficeLocationService();

  @override
  Future<Map<String, dynamic>> checkAttendanceStatus({
    required String uid,
  }) async {
    try {
      // 1. Check Geofencing
      final position = await locationService.getCurrentPosition();
      bool isInsideGeofence = false;
      double? closestDistance;

      // Get office locations from Firestore
      final officeLocations = await officeLocationService
          .getActiveOfficeLocationsOneShot();

      if (officeLocations.isNotEmpty) {
        for (var office in officeLocations) {
          double distanceInMeters = geolocator.Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            office.location.latitude,
            office.location.longitude,
          );

          if (distanceInMeters <= constants.AppConstants.geofenceRadius) {
            isInsideGeofence = true;
            closestDistance = distanceInMeters;
            break;
          } else {
            if (closestDistance == null || distanceInMeters < closestDistance) {
              closestDistance = distanceInMeters;
            }
          }
        }
      }

      // 2. Check Face Data
      final doc = await firestoreInstance.collection('users').doc(uid).get();

      final data = doc.data();
      bool hasFaceData =
          doc.exists &&
          data != null &&
          (data['faceDataBase64'] != null &&
              (data['faceDataBase64'] as String).isNotEmpty);

      return {
        'isInOfficeArea': isInsideGeofence,
        'hasFaceData': hasFaceData,
        'distanceInMeters': closestDistance,
      };
    } on firestore.FirebaseException catch (e) {
      throw exceptions.ServerException(e.message ?? 'Firestore error');
    } catch (e) {
      throw exceptions.ServerException(e.toString());
    }
  }

  @override
  Future<void> recordAttendance({
    required String uid,
    required String email,
    required String type,
  }) async {
    try {
      final position = await locationService.getCurrentPosition();
      final now = DateTime.now();
      final today = models.AttendanceModel.formatDate(now);
      final timeStr = models.AttendanceModel.formatTime(now);

      final attendanceRef = firestoreInstance
          .collection('users')
          .doc(uid)
          .collection('attendance')
          .doc(today);

      await attendanceRef.set({
        'userId': uid,
        'email': email,
        'tanggal': today,
        'timestamp': firestore.FieldValue.serverTimestamp(),
        'lat': position.latitude,
        'long': position.longitude,
        if (type == 'Masuk') 'MasukTime': timeStr,
        if (type == 'Keluar') 'KeluarTime': timeStr,
      }, firestore.SetOptions(merge: true));
    } on firestore.FirebaseException catch (e) {
      throw exceptions.ServerException(e.message ?? 'Firestore error');
    } catch (e) {
      throw exceptions.ServerException(e.toString());
    }
  }

  @override
  Future<List<models.AttendanceModel>> getAttendanceHistory({
    required String uid,
  }) async {
    try {
      final querySnapshot = await firestoreInstance
          .collection('users')
          .doc(uid)
          .collection('attendance')
          .orderBy('tanggal', descending: true)
          .limit(30)
          .get();

      return querySnapshot.docs
          .map((doc) => models.AttendanceModel.fromJson(doc.data(), doc.id))
          .toList();
    } on firestore.FirebaseException catch (e) {
      throw exceptions.ServerException(e.message ?? 'Firestore error');
    } catch (e) {
      throw exceptions.ServerException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>?> getTodayAttendance({
    required String uid,
  }) async {
    try {
      final now = DateTime.now();
      final today = models.AttendanceModel.formatDate(now);

      final attendanceDoc = await firestoreInstance
          .collection('users')
          .doc(uid)
          .collection('attendance')
          .doc(today)
          .get();

      if (attendanceDoc.exists) {
        return attendanceDoc.data();
      }
      return null;
    } on firestore.FirebaseException catch (e) {
      throw exceptions.ServerException(e.message ?? 'Firestore error');
    } catch (e) {
      throw exceptions.ServerException(e.toString());
    }
  }
}

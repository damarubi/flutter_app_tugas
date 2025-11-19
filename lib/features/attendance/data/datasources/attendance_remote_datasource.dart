import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:geolocator/geolocator.dart' as geolocator;
import '../models/attendance_model.dart' as models;
import '../../../../core/errors/exceptions.dart' as exceptions;
import '../../../../shared/services/location_service.dart' as services;
import '../../../../core/constants/app_constants.dart' as constants;
import '../../../../core/services/office_location_service.dart';

abstract class AttendanceRemoteDataSource {
  Future<Map<String, dynamic>> checkAttendanceStatus();
  Future<void> recordAttendance({required String type});
  Future<List<models.AttendanceModel>> getAttendanceHistory();
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;
  final firestore.FirebaseFirestore firestoreInstance;
  final services.LocationService locationService;
  final OfficeLocationService officeLocationService;

  AttendanceRemoteDataSourceImpl({
    required this.firebaseAuth,
    required firestore.FirebaseFirestore firestore,
    required this.locationService,
    OfficeLocationService? officeLocationService,
  }) : firestoreInstance = firestore,
       officeLocationService = officeLocationService ?? OfficeLocationService();

  @override
  Future<Map<String, dynamic>> checkAttendanceStatus() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw exceptions.AuthException('User tidak terautentikasi.');
      }

      // 1. Check Geofencing
      final position = await locationService.getCurrentPosition();
      bool isInsideGeofence = false;
      double? closestDistance;

      // Get office locations from Firestore
      final officeLocations = await officeLocationService
          .getActiveOfficeLocations()
          .first;

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
      final doc = await firestoreInstance
          .collection('users')
          .doc(user.uid)
          .get();
      bool hasFaceData =
          doc.exists &&
          doc.data() != null &&
          doc.data()!['faceDataBase64'] != null;

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
  Future<void> recordAttendance({required String type}) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw exceptions.AuthException('User tidak terautentikasi.');
      }

      final position = await locationService.getCurrentPosition();
      final now = DateTime.now();
      final today = models.AttendanceModel.formatDate(now);
      final timeStr = models.AttendanceModel.formatTime(now);

      final attendanceRef = firestoreInstance
          .collection('users')
          .doc(user.uid)
          .collection('attendance')
          .doc(today);

      await attendanceRef.set({
        'userId': user.uid,
        'email': user.email,
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
  Future<List<models.AttendanceModel>> getAttendanceHistory() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw exceptions.AuthException('User tidak terautentikasi.');
      }

      final querySnapshot = await firestoreInstance
          .collection('users')
          .doc(user.uid)
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
}

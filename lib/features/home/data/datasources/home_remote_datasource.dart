import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:geolocator/geolocator.dart';
import '../models/dashboard_model.dart' as models;
import '../../../../shared/services/location_service.dart' as services;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/office_location_service.dart';

abstract class HomeRemoteDataSource {
  Future<models.DashboardModel> getDashboardData();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;
  final firestore.FirebaseFirestore firestoreInstance;
  final services.LocationService locationService;
  final OfficeLocationService officeLocationService;

  HomeRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestoreInstance,
    required this.locationService,
    OfficeLocationService? officeLocationService,
  }) : officeLocationService = officeLocationService ?? OfficeLocationService();

  @override
  Future<models.DashboardModel> getDashboardData() async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User tidak login.');
    }

    // 1. Get User Data
    final userDoc = await firestoreInstance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!userDoc.exists || userDoc.data() == null) {
      throw Exception('Data user tidak ditemukan.');
    }
    final userData = userDoc.data()!;

    // 2. Get Today's Attendance
    final today = _formatDate(DateTime.now());
    final attendanceDoc = await firestoreInstance
        .collection('users')
        .doc(user.uid)
        .collection('attendance')
        .doc(today)
        .get();
    final attendanceData = attendanceDoc.exists ? attendanceDoc.data() : null;

    // 3. Get Monthly Attendance Count
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final monthlySnapshot = await firestoreInstance
        .collection('users')
        .doc(user.uid)
        .collection('attendance')
        .where('tanggal', isGreaterThanOrEqualTo: _formatDate(startOfMonth))
        .where('tanggal', isLessThanOrEqualTo: _formatDate(endOfMonth))
        .get();

    final monthlyCount = monthlySnapshot.docs.length;

    // 4. Get Location and Calculate Distance
    double? distance;
    bool inOfficeArea = false;

    try {
      final position = await locationService.getCurrentPosition();

      // Get office locations from Firestore
      final officeLocations = await officeLocationService
          .getActiveOfficeLocations()
          .first;

      if (officeLocations.isEmpty) {
        // No office locations available
        distance = null;
        inOfficeArea = false;
      } else {
        // Check distance to nearest office
        double minDistance = double.infinity;
        for (var office in officeLocations) {
          final officeDistance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            office.location.latitude,
            office.location.longitude,
          );

          if (officeDistance < minDistance) {
            minDistance = officeDistance;
          }
        }

        distance = minDistance;
        inOfficeArea = minDistance <= AppConstants.geofenceRadius;
      }
    } catch (e) {
      // Location service error, keep distance as null
      distance = null;
      inOfficeArea = false;
    }

    return models.DashboardModel.fromFirestore(
      userData: userData,
      attendanceData: attendanceData,
      monthlyCount: monthlyCount,
      distance: distance,
      inOfficeArea: inOfficeArea,
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

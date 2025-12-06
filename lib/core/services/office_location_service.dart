import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/office_location.dart';

class OfficeLocationService {
  final FirebaseFirestore _firestore;

  OfficeLocationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get all active office locations (One-time fetch)
  Future<List<OfficeLocation>> getActiveOfficeLocationsOneShot() async {
    try {
      final snapshot = await _firestore
          .collection('officeLocations')
          .where('isActive', isEqualTo: true)
          .get();
      
      return snapshot.docs
          .map((doc) => OfficeLocation.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting active office locations: $e');
      return [];
    }
  }

  /// Get all active office locations
  Stream<List<OfficeLocation>> getActiveOfficeLocations() {
    return _firestore
        .collection('officeLocations')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OfficeLocation.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  /// Get all office locations (including inactive)
  Stream<List<OfficeLocation>> getAllOfficeLocations() {
    return _firestore.collection('officeLocations').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => OfficeLocation.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get single office location by ID
  Future<OfficeLocation?> getOfficeLocationById(String id) async {
    try {
      final doc = await _firestore.collection('officeLocations').doc(id).get();
      if (doc.exists) {
        return OfficeLocation.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting office location: $e');
      return null;
    }
  }

  /// Add new office location
  Future<String?> addOfficeLocation(OfficeLocation location) async {
    try {
      final docRef = await _firestore
          .collection('officeLocations')
          .add(location.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error adding office location: $e');
      return null;
    }
  }

  /// Update office location
  Future<bool> updateOfficeLocation(OfficeLocation location) async {
    try {
      await _firestore
          .collection('officeLocations')
          .doc(location.id)
          .update(location.toFirestore());
      return true;
    } catch (e) {
      print('Error updating office location: $e');
      return false;
    }
  }

  /// Delete office location (soft delete by setting isActive to false)
  Future<bool> deactivateOfficeLocation(String id) async {
    try {
      await _firestore.collection('officeLocations').doc(id).update({
        'isActive': false,
      });
      return true;
    } catch (e) {
      print('Error deactivating office location: $e');
      return false;
    }
  }

  /// Permanently delete office location
  Future<bool> deleteOfficeLocation(String id) async {
    try {
      await _firestore.collection('officeLocations').doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting office location: $e');
      return false;
    }
  }
}

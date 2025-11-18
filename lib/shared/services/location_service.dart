import 'package:geolocator/geolocator.dart';
import '../../core/errors/exceptions.dart';

class LocationService {
  /// Determine the current position of the device
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('Layanan lokasi tidak diaktifkan.');
    }

    // Check for location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Izin lokasi ditolak secara permanen, tidak dapat meminta izin.',
      );
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Calculate distance between two points in meters
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Check if current position is within a geofence
  Future<bool> isWithinGeofence({
    required double centerLatitude,
    required double centerLongitude,
    required double radiusInMeters,
  }) async {
    final position = await getCurrentPosition();

    final distance = calculateDistance(
      startLatitude: position.latitude,
      startLongitude: position.longitude,
      endLatitude: centerLatitude,
      endLongitude: centerLongitude,
    );

    return distance <= radiusInMeters;
  }
}

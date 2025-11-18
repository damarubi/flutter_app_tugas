import 'package:geolocator/geolocator.dart' as geolocator;
import '../../core/errors/exceptions.dart' as exceptions;

class LocationService {
  /// Determine the current position of the device
  Future<geolocator.Position> getCurrentPosition() async {
    bool serviceEnabled;
    geolocator.LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw exceptions.LocationException('Layanan lokasi tidak diaktifkan.');
    }

    // Check for location permissions
    permission = await geolocator.Geolocator.checkPermission();
    if (permission == geolocator.LocationPermission.denied) {
      permission = await geolocator.Geolocator.requestPermission();
      if (permission == geolocator.LocationPermission.denied) {
        throw exceptions.LocationException('Izin lokasi ditolak.');
      }
    }

    if (permission == geolocator.LocationPermission.deniedForever) {
      throw exceptions.LocationException(
        'Izin lokasi ditolak secara permanen, tidak dapat meminta izin.',
      );
    }

    return await geolocator.Geolocator.getCurrentPosition(
      desiredAccuracy: geolocator.LocationAccuracy.high,
    );
  }

  /// Calculate distance between two points in meters
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return geolocator.Geolocator.distanceBetween(
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

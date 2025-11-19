import 'package:latlong2/latlong.dart';

class OfficeLocation {
  final String id;
  final String name;
  final LatLng location;
  final bool isActive;

  OfficeLocation({
    required this.id,
    required this.name,
    required this.location,
    this.isActive = true,
  });

  factory OfficeLocation.fromFirestore(Map<String, dynamic> data, String id) {
    return OfficeLocation(
      id: id,
      name: data['name'] as String,
      location: LatLng(data['latitude'] as double, data['longitude'] as double),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'isActive': isActive,
    };
  }
}

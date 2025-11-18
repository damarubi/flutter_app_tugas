import 'package:latlong2/latlong.dart';

class AppConstants {
  AppConstants._();

  // Geofencing
  static const double geofenceRadius = 100.0; // meters

  // Office Locations
  static const List<Map<String, dynamic>> officeLocations = [
    {'name': 'Kantor Pusat Yogyakarta', 'location': LatLng(-7.7478, 110.3553)},
    {
      'name': 'Kantor Cabang',
      'location': LatLng(-7.805830924332875, 110.38896483238734),
    },
    {
      'name': 'Departement IT',
      'location': LatLng(-7.747265459292401, 110.34368731455378),
    },
  ];

  // API Constants
  static const String baseUrl = '';

  // Storage Keys
  static const String userToken = 'user_token';
  static const String userId = 'user_id';

  // Image Quality
  static const int imageQuality = 50;

  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm:ss';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'dd MMMM yyyy';
}

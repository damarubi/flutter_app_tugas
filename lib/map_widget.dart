import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapWidget extends StatefulWidget {
  final List<LatLng> locations;
  final List<String> officeNames;
  final Position? currentPosition;
  final double geofenceRadius;
  final int selectedOfficeIndex;

  const MapWidget({
    super.key,
    required this.locations,
    required this.officeNames,
    this.currentPosition,
    this.geofenceRadius = 100.0,
    this.selectedOfficeIndex = 0,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pindahkan map ke kantor yang dipilih dengan animasi
    if (oldWidget.selectedOfficeIndex != widget.selectedOfficeIndex) {
      _animateToLocation(widget.locations[widget.selectedOfficeIndex]);
    }
  }

  void _animateToLocation(LatLng location) {
    _mapController.move(location, 16.0);
  }

  void _moveToMyLocation() {
    if (widget.currentPosition != null) {
      final myLocation = LatLng(
        widget.currentPosition!.latitude,
        widget.currentPosition!.longitude,
      );
      _mapController.move(myLocation, 17.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // MapTiler API Key
    const String mapTilerApiKey = '1E0iwi3KFr4pU5G3hceg';

    // Fokus ke kantor yang dipilih
    final LatLng centerLocation = widget.locations[widget.selectedOfficeIndex];

    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: centerLocation,
                initialZoom: 16,
                minZoom: 10,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$mapTilerApiKey',
                  userAgentPackageName: 'com.example.flutter_app_tugas',
                ),

                // Geofencing circles untuk semua kantor (garis putus-putus hitam transparan)
                CircleLayer(
                  circles: widget.locations.asMap().entries.map((entry) {
                    final index = entry.key;
                    final location = entry.value;
                    final isSelected = index == widget.selectedOfficeIndex;

                    return CircleMarker(
                      point: location,
                      color: const Color(
                        0xFFFFA778,
                      ).withOpacity(0.5), // FFA778 dengan 50% transparansi
                      radius: widget.geofenceRadius,
                      borderColor: Colors.black.withOpacity(
                        0.4,
                      ), // Hitam transparan
                      borderStrokeWidth: isSelected ? 2.5 : 2,
                      useRadiusInMeter: true,
                    );
                  }).toList(),
                ),

                // Circle layer untuk akurasi posisi user (seperti Google Maps)
                if (widget.currentPosition != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: LatLng(
                          widget.currentPosition!.latitude,
                          widget.currentPosition!.longitude,
                        ),
                        color: Colors.blue.withOpacity(0.15),
                        radius: widget.currentPosition!.accuracy,
                        borderColor: Colors.blue.withOpacity(0.3),
                        borderStrokeWidth: 1,
                        useRadiusInMeter: true,
                      ),
                    ],
                  ),

                // Markers untuk posisi user (titik biru seperti Google Maps)
                MarkerLayer(
                  markers: [
                    // Marker untuk posisi user saat ini (titik biru dengan border putih)
                    if (widget.currentPosition != null)
                      Marker(
                        point: LatLng(
                          widget.currentPosition!.latitude,
                          widget.currentPosition!.longitude,
                        ),
                        width: 24,
                        height: 24,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            // Tombol My Location di pojok kiri
            if (widget.currentPosition != null)
              Positioned(
                left: 16,
                bottom: 16,
                child: Material(
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _moveToMyLocation,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

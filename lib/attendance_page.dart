import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  // Daftar lokasi kantor yang akan dicek untuk geofencing
  final List<LatLng> officeLocations = [
    // Kantor 1: 7°44'52.1"S 110°21'19.2"E
    const LatLng(-7.7478, 110.3553),
    // Kantor 2: 7°47'01.1"S 110°19'01.8"E
    const LatLng(-7.7836, 110.3172),
  ];

  Future<void> _recordAttendance(String type) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Check geo-fencing for all office locations
      final position = await _determinePosition();
      bool isInOfficeArea = false;
      String distanceMessage = 'Anda berada di luar area kantor.';

      for (var officeLocation in officeLocations) {
        final distanceInMeters = Geolocator.distanceBetween(
          officeLocation.latitude,
          officeLocation.longitude,
          position.latitude,
          position.longitude,
        );
        if (distanceInMeters <= 100) {
          isInOfficeArea = true;
          break;
        }
      }

      if (!isInOfficeArea) {
        throw Exception(distanceMessage);
      }
      
      // Mengambil data wajah pengguna dari Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final hasFaceData = userDoc.data()?['faceDataBase64'] != null;

      if (!hasFaceData) {
        throw Exception('Data wajah belum terdaftar. Silahkan registrasi wajah terlebih dahulu.');
      }
      
      // Record attendance in Firestore
      await FirebaseFirestore.instance.collection('attendance').add({
        'userId': user.uid,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'location': GeoPoint(position.latitude, position.longitude),
      });

      // Show success dialog
      _showSuccessDialog(context, type);
    } catch (e) {
      _showErrorDialog(context, e.toString());
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Layanan lokasi tidak diaktifkan.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Izin lokasi ditolak permanen. Silakan ubah di pengaturan.');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _showSuccessDialog(BuildContext context, String type) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 16),
              const Text('Terupdate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 8),
              Text(
                'Kamu berhasil melakukan Absensi ${type.toLowerCase()}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OKE', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Absensi Gagal'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Terjadi kesalahan saat memuat data.'));
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final fullName = userData?['fullName'] ?? 'Nama Tidak Ditemukan';
          final nip = userData?['nip'] ?? 'NIP Tidak Ditemukan';
          final hasFaceData = userData?['faceDataBase64'] != null;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: hasFaceData
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black, width: 2),
                                  color: Colors.black, // Placeholder for camera view
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                fullName,
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'NIP: $nip',
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              const Text(
                                'Jabatan Karyawan',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              const SizedBox(height: 40),
                              ElevatedButton(
                                onPressed: () => _recordAttendance('Masuk'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: const Text('Clock In', style: TextStyle(color: Colors.white, fontSize: 18)),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _recordAttendance('Keluar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: const Text('Clock Out', style: TextStyle(color: Colors.white, fontSize: 18)),
                              ),
                            ],
                          )
                        : const Text(
                            'Silahkan daftarkan wajah Anda di halaman Akun terlebih dahulu.',
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
}
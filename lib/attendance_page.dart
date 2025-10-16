import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  String _statusMessage = 'Mengecek lokasi dan data wajah...';
  bool _isLoading = true;
  bool _isInOfficeArea = false;
  bool _hasFaceData = false;
  String? _distanceMessage;

  // Daftar lokasi kantor yang akan dicek untuk geofencing
  final List<LatLng> officeLocations = [
    // Kantor 1: 7°44'52.1"S 110°21'19.2"E
    const LatLng(-7.7478, 110.3553),
    // Kantor 2: 7°47'01.1"S 110°19'01.8"E
    const LatLng(-7.7836, 110.3172),
  ];

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isLoading = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _statusMessage = 'User tidak terautentikasi.';
        _isLoading = false;
      });
      return;
    }

    // 1. Cek Geofencing
    try {
      final position = await _determinePosition();
      bool isInsideGeofence = false;
      String closestDistanceMessage = 'Mengecek jarak...';

      for (var office in officeLocations) {
        double distanceInMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          office.latitude,
          office.longitude,
        );

        if (distanceInMeters <= 100) {
          isInsideGeofence = true;
          closestDistanceMessage =
              'Anda berada di dalam area kantor.';
          break;
        } else {
          closestDistanceMessage =
              'Anda berada ${distanceInMeters.toStringAsFixed(2)} meter di luar area kantor.';
        }
      }

      setState(() {
        _isInOfficeArea = isInsideGeofence;
        _distanceMessage = closestDistanceMessage;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Gagal mendapatkan lokasi: $e';
        _isLoading = false;
        return;
      });
    }

    // 2. Cek Data Wajah
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    bool faceDataExists = doc.exists && doc.data() != null && doc.data()!['faceDataBase64'] != null;

    setState(() {
      _hasFaceData = faceDataExists;
      _isLoading = false;
    });

    // PERBAIKAN: Memperbarui status message secara kondisional
    if (!_isInOfficeArea) {
      _statusMessage = 'Anda tidak berada di area kantor.';
    } else if (!_hasFaceData) {
      _statusMessage = 'Silahkan daftarkan wajah Anda di halaman Akun terlebih dahulu.';
    } else {
      _statusMessage = 'Verifikasi berhasil! Anda dapat melakukan absensi.';
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
      return Future.error('Izin lokasi ditolak secara permanen, tidak dapat meminta izin.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _recordAttendance(String type) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final now = DateFormat('HH:mm:ss').format(DateTime.now());

      final attendanceRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('attendance')
          .doc(today);

      await attendanceRef.set(
        {
          'email': user.email,
          'tanggal': today,
          'timestamp': FieldValue.serverTimestamp(),
          'lat': (await _determinePosition()).latitude,
          'long': (await _determinePosition()).longitude,
          if (type == 'Masuk') 'MasukTime': now,
          if (type == 'Keluar') 'KeluarTime': now,
        },
        SetOptions(merge: true),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Absensi $type berhasil!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal merekam absensi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canAbsen = _isInOfficeArea && _hasFaceData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            canAbsen ? Icons.check_circle : Icons.error,
                            color: canAbsen ? Colors.green : Colors.red,
                            size: 80,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _statusMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: canAbsen ? Colors.green[800] : Colors.red[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_distanceMessage != null)
                            Text(
                              _distanceMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: canAbsen ? Colors.grey[600] : Colors.red[400],
                              ),
                            ),
                          const SizedBox(height: 24),
                          if (canAbsen)
                            Column(
                              children: [
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
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
}
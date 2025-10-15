import 'package:flutter/material.dart';
import 'package:flutter_app_tugas/map_widget.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _clockInTime = '--:--';
  String _clockOutTime = '--:--';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Mendapatkan tanggal hari ini dalam format YYYY-MM-DD
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('attendance')
        .doc(today)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          setState(() {
            _clockInTime = data['clockInTime'] ?? '--:--';
            _clockOutTime = data['clockOutTime'] ?? '--:--';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _clockInTime = '--:--';
          _clockOutTime = '--:--';
          _isLoading = false;
        });
      }
    });
  }

  // Lokasi kantor yang sudah kita definisikan
  final officeLocations = [
    const LatLng(-7.7478, 110.3553), // Kantor 1
    const LatLng(-7.7836, 110.3172), // Kantor 2
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Widget "Cari Zona Absen"
            _buildSearchBar(),
            const SizedBox(height: 16),
            // Peta Kantor 1
            const Text(
              'Kantor 1 (Yogyakarta)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            MapWidget(location: officeLocations[0]),
            const SizedBox(height: 16),
            // Status Absensi
            _buildAttendanceStatus(),
            const SizedBox(height: 16),
            // Peta Kantor 2
            const Text(
              'Kantor 2 (Yogyakarta)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            MapWidget(location: officeLocations[1]),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'Cari Zona Absen...',
          border: InputBorder.none,
          icon: Icon(Icons.search),
        ),
      ),
    );
  }

  Widget _buildAttendanceStatus() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasClockIn = _clockInTime != '--:--';
    final hasClockOut = _clockOutTime != '--:--';
    final isAbsent = !hasClockIn;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Status Absensi Hari Ini',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (isAbsent) ...[
            const Text(
              'Anda belum absen hari ini',
              style: TextStyle(color: Colors.red),
            ),
          ] else ...[
            Text(
              'Anda sudah Clock In hari ini',
              style: TextStyle(color: Colors.green),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _buildClockButton(label: 'Clock In', time: _clockInTime, isClocked: hasClockIn),
              const SizedBox(width: 16),
              _buildClockButton(label: 'Clock Out', time: _clockOutTime, isClocked: hasClockOut),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClockButton({required String label, required String time, required bool isClocked}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isClocked ? (label == 'Clock In' ? Colors.green[50] : Colors.red[50]) : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isClocked ? (label == 'Clock In' ? Colors.green : Colors.red) : Colors.grey[400]!,
          ),
        ),
        child: Column(
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                color: isClocked ? (label == 'Clock In' ? Colors.green : Colors.red) : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isClocked ? (label == 'Clock In' ? Colors.green : Colors.red) : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
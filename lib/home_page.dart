import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app_tugas/map_widget.dart';
import 'package:latlong2/latlong.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final officeLocations = [
    const LatLng(-7.7478, 110.3553), // Kantor 1
    const LatLng(-7.7836, 110.3172), // Kantor 2
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('User not logged in'));
    }

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

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
            _buildSearchBar(),
            const SizedBox(height: 16),
            const Text(
              'Kantor 1 (Yogyakarta)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            MapWidget(location: officeLocations[0]),
            const SizedBox(height: 16),
            const Text(
              'Kantor 2 (Yogyakarta)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            MapWidget(location: officeLocations[1]),
            const SizedBox(height: 24),

            // StreamBuilder untuk menampilkan status absensi
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('attendance')
                  .doc(today)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Text('Terjadi kesalahan saat memuat data.');
                }

                final attendanceData = snapshot.data?.data() as Map<String, dynamic>?;
                final clockInTime = attendanceData?['MasukTime'] as String?;
                final clockOutTime = attendanceData?['KeluarTime'] as String?;

                return _buildAttendanceCard(
                  clockInTime: clockInTime,
                  clockOutTime: clockOutTime,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.search, color: Colors.grey),
          SizedBox(width: 8),
          Text('Cari Zona Absen', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard({String? clockInTime, String? clockOutTime}) {
    bool hasAbsen = clockInTime != null;
    bool hasAbsenKeluar = clockOutTime != null;

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
        children: [
          const Text(
            'Absensi Hari Ini',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const Divider(height: 24),
          if (!hasAbsen)
            const Text(
              'Anda belum absen hari ini',
              style: TextStyle(color: Colors.red),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildClockButton(
                label: 'Clock In',
                time: clockInTime ?? '--:--',
                isFilled: hasAbsen,
              ),
              const SizedBox(width: 16),
              _buildClockButton(
                label: 'Clock Out',
                time: clockOutTime ?? '--:--',
                isFilled: hasAbsenKeluar,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClockButton({
    required String label,
    required String time,
    required bool isFilled,
  }) {
    Color containerColor = isFilled ? Colors.green[50]! : Colors.grey[200]!;
    Color borderColor = isFilled ? Colors.green : Colors.grey[400]!;
    Color labelColor = isFilled ? Colors.green : Colors.black;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: Colors.black87,
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
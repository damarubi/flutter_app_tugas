import 'package:flutter/material.dart';
import 'main.dart'; // Impor file main.dart; // Impor file main.dart

class SuccessPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9C5A7),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const CircleAvatar(
              radius: 70,
              backgroundColor: Colors.green,
              child: Icon(Icons.check, color: Colors.white, size: 90),
            ),
            const SizedBox(height: 30),
            const Text(
              'Pendaftaran Berhasil',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            const Text(
              'Proses pendaftaran Face Recognition Anda berhasil. Untuk melakukan Absensi, Anda cukup melakukan scan pada saat absensi dibuka',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // Kembali ke halaman utama dan hapus semua rute sebelumnya
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MainPage()),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('SELESAI', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
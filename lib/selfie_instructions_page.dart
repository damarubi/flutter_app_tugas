import 'package:flutter/material.dart';
import 'camera_page.dart'; // Impor halaman kamera

class SelfieInstructionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9C5A7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Foto Selfie',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildExampleCard(Colors.lightBlue.shade100, Icons.check_circle, 'Benar', true),
                _buildExampleCard(const Color(0xFFE8DDCF), Icons.cancel, 'Salah', false),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Cara Mengambil Foto Selfie',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildInstructionPoint('1.', 'Foto selfie harus diambil langsung melalui kamera.'),
            _buildInstructionPoint('2.', 'Pastikan saat melakukan pengambilan gambar cahaya mencukupi, agar wajah anda terlihat jelas dan tidak gelap atau kabur.'),
            _buildInstructionPoint('3.', 'Sesuaikan posisi wajah anda dengan area foto yang telah disiapkan.'),
            _buildInstructionPoint('4.', 'Pastikan wajah terlihat jelas, tidak terpotong.'),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CameraPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('AMBIL FOTO', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleCard(Color bgColor, IconData icon, String label, bool isCorrect) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 150,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: Icon(Icons.person, size: 80, color: isCorrect ? Colors.black : Colors.black54),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, color: isCorrect ? Colors.blue : Colors.red, size: 20),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  Widget _buildInstructionPoint(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(number, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
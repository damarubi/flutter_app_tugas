import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app_tugas/login_page.dart'; // Impor untuk tombol Keluar Akun
 // Buat halaman ini di langkah selanjutnya

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // Fungsi untuk logout
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Jika tidak ada pengguna yang login, kembali ke halaman login
      return const LoginPage();
    }

    // Mengambil data pengguna dari Cloud Firestore
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Terjadi kesalahan saat memuat data.')),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Data pengguna tidak ditemukan.')),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final fullName = userData['fullName'] ?? 'Nama Tidak Ditemukan';
        final nip = userData['nip'] ?? 'NIP Tidak Ditemukan';
        
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Akun',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Bagian atas (Informasi Pengguna)
                _buildProfileCard(fullName, nip),
                const SizedBox(height: 24.0),

                // Bagian Data Diri
                _buildSectionTitle('DATA DIRI'),
                _buildDataCard(
                  icon: Icons.person,
                  label: fullName,
                  value: 'NIP: $nip',
                  iconColor: Colors.black,
                  isBold: true,
                ),
                _buildDataCard(
                  icon: Icons.mail_outline,
                  label: 'NIP',
                  value: nip,
                  iconColor: Colors.black,
                ),
                const SizedBox(height: 24.0),

                // Bagian Data Absensi
                _buildSectionTitle('DATA ABSENSI'),
                _buildActionCard(
                  context,
                  icon: Icons.history,
                  label: 'Riwayat Absensi',
                  onTap: () {
                    // TODO: Navigasi ke halaman Riwayat Absensi
                  },
                ),
                _buildActionCard(
                  context,
                  icon: Icons.face_retouching_natural,
                  label: 'Registrasi Face Recognition',
                  onTap: () {
                  },
                ),
                const SizedBox(height: 24.0),

                // Bagian Keluar Akun
                _buildSectionTitle('AKUN'),
                _buildActionCard(
                  context,
                  icon: Icons.logout,
                  label: 'Keluar Akun',
                  isLogout: true,
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  // Widget untuk kartu profil utama
  Widget _buildProfileCard(String fullName, String nip) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'NIP: $nip',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 8.0),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Aktif',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk judul seksi
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black54,
          fontSize: 14,
        ),
      ),
    );
  }

  // Widget untuk menampilkan data diri
  Widget _buildDataCard({
    required IconData icon,
    required String label,
    String? value,
    required Color iconColor,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: iconColor),
          const SizedBox(width: 16.0),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (value != null)
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  // Widget untuk kartu yang bisa diklik
  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isLogout = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.only(bottom: 8.0),
        decoration: BoxDecoration(
          color: isLogout ? Colors.red[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              color: isLogout ? Colors.red : Colors.black,
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isLogout ? Colors.red : Colors.black,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isLogout ? Colors.red : Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner),
          label: 'Presensi',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Akun',
        ),
      ],
      currentIndex: 2, // Indeks 2 untuk halaman "Akun"
      onTap: (index) {
        // TODO: Tambahkan logika navigasi untuk Bottom Navigation Bar
      },
    );
  }
}
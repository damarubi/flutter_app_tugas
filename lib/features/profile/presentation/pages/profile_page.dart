import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart' as provider;
import '../../../auth/presentation/pages/login_page.dart';
import '../../../face_recognition/presentation/pages/face_recognition_page.dart';
import '../providers/profile_provider.dart' as providers;
import '../../data/datasources/profile_remote_datasource.dart' as datasources;
import '../../data/repositories/profile_repository_impl.dart' as repositories;
import '../../domain/usecases/get_user_profile_usecase.dart' as usecases;
import '../../domain/usecases/logout_usecase.dart' as usecases;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late providers.ProfileProvider _profileProvider;

  @override
  void initState() {
    super.initState();
    _initializeProvider();
  }

  void _initializeProvider() {
    // Initialize dependencies
    final dataSource = datasources.ProfileRemoteDataSourceImpl(
      firebaseAuth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
    );
    final repository = repositories.ProfileRepositoryImpl(
      remoteDataSource: dataSource,
    );

    _profileProvider = providers.ProfileProvider(
      getUserProfileUseCase: usecases.GetUserProfileUseCase(repository),
      logoutUseCase: usecases.LogoutUseCase(repository),
    );
  }

  void _logout(BuildContext context) async {
    await _profileProvider.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const LoginPage();
    }

    return provider.ChangeNotifierProvider.value(
      value: _profileProvider,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Akun',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: StreamBuilder(
          stream: _profileProvider.getUserProfileStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text('Terjadi kesalahan saat memuat data.'),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: Text('Data pengguna tidak ditemukan.'),
              );
            }

            final userProfile = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Bagian atas (Informasi Pengguna)
                  _buildProfileCard(
                    userProfile.fullName,
                    userProfile.nip,
                    userProfile.isActive,
                    userProfile.faceDataBase64,
                  ),
                  const SizedBox(height: 24.0),

                  // Bagian Data Diri
                  _buildSectionTitle('DATA DIRI'),
                  _buildDataCard(
                    icon: Icons.person,
                    label: userProfile.fullName,
                    value: 'NIP: ${userProfile.nip}',
                    iconColor: Colors.black,
                    isBold: true,
                  ),
                  _buildDataCard(
                    icon: Icons.badge,
                    label: 'NIP',
                    value: userProfile.nip,
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FaceRecognitionPage(),
                        ),
                      );
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
                  const SizedBox(height: 50),
                  const Center(
                    child: Text(
                      'Absen.In - VERSI 1.1.0\n2025',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileCard(
      String fullName, String nip, bool isActive, String? faceDataBase64) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: <Widget>[
          // Profile Photo from Face Recognition
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey,
            backgroundImage: faceDataBase64 != null &&
                    faceDataBase64.isNotEmpty
                ? MemoryImage(
                    base64Decode(
                      faceDataBase64.contains(',')
                          ? faceDataBase64.split(',').last
                          : faceDataBase64,
                    ),
                  )
                : null,
            child: faceDataBase64 == null || faceDataBase64.isEmpty
                ? const Icon(Icons.person, size: 40, color: Colors.white)
                : null,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'Aktif' : 'Tidak Aktif',
                    style: const TextStyle(
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
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

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
            Icon(icon, color: isLogout ? Colors.red : Colors.black),
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
}

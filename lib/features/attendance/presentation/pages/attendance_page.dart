import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:camera/camera.dart';
import '../providers/attendance_provider.dart' as providers;
import '../../data/datasources/attendance_remote_datasource.dart'
    as datasources;
import '../../data/repositories/attendance_repository_impl.dart'
    as repositories;
import '../../domain/usecases/check_attendance_status_usecase.dart' as usecases;
import '../../domain/usecases/record_attendance_usecase.dart' as usecases;
import '../../../../shared/services/location_service.dart' as services;
import '../../../auth/domain/entities/user.dart' as entities;

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late providers.AttendanceProvider _attendanceProvider;
  entities.User? _currentUser;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeProvider();
    _loadUserData();
    _checkStatus();
    _initializeCamera();
  }

  void _initializeProvider() {
    // Initialize dependencies
    final locationService = services.LocationService();
    final dataSource = datasources.AttendanceRemoteDataSourceImpl(
      firebaseAuth: firebase_auth.FirebaseAuth.instance,
      firestore: firestore.FirebaseFirestore.instance,
      locationService: locationService,
    );
    final repository = repositories.AttendanceRepositoryImpl(
      remoteDataSource: dataSource,
    );

    _attendanceProvider = providers.AttendanceProvider(
      checkStatusUseCase: usecases.CheckAttendanceStatusUseCase(repository),
      recordAttendanceUseCase: usecases.RecordAttendanceUseCase(repository),
    );
  }

  Future<void> _loadUserData() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _currentUser = entities.User(
            uid: user.uid,
            email: data['email'] ?? '',
            fullName: data['fullName'] ?? '',
            nip: data['nip'] ?? '',
            faceDataBase64: data['faceDataBase64'],
          );
        });
      }
    }
  }

  Future<void> _checkStatus() async {
    await _attendanceProvider.checkStatus();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Pilih front camera untuk face recognition
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _recordAttendance(String type) async {
    final success = await _attendanceProvider.recordAttendance(type);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Absensi $type berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
        await _checkStatus(); // Refresh status
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _attendanceProvider.errorMessage ?? 'Gagal merekam absensi',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return provider.ChangeNotifierProvider.value(
      value: _attendanceProvider,
      child: provider.Consumer<providers.AttendanceProvider>(
        builder: (context, provider, child) {
          final canAbsen = provider.isInOfficeArea && provider.hasFaceData;

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: const Text(
                'Face Recognition',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.white,
              elevation: 0,
            ),
            body: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                const SizedBox(height: 40),
                                // Camera Preview (Real-time) - Circular
                                _isCameraInitialized &&
                                        _cameraController != null
                                    ? Center(
                                        child: Container(
                                          width: 340,
                                          height: 340,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                              width: 4,
                                            ),
                                          ),
                                          child: ClipOval(
                                            child: OverflowBox(
                                              alignment: Alignment.center,
                                              child: FittedBox(
                                                fit: BoxFit.cover,
                                                child: SizedBox(
                                                  width: 340,
                                                  height:
                                                      340 *
                                                      _cameraController!
                                                          .value
                                                          .aspectRatio,
                                                  child: CameraPreview(
                                                    _cameraController!,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 340,
                                        height: 340,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                            width: 4,
                                          ),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                const SizedBox(height: 32),
                                // User Name
                                Text(
                                  _currentUser?.fullName ?? 'Loading...',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // NIP and Position
                                Text(
                                  '${_currentUser?.nip ?? ''} - Jabatan Karyawan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Status Message Above Buttons
                      if (!canAbsen)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 24.0),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange[200]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange[700],
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  provider.statusMessage,
                                  style: TextStyle(
                                    color: Colors.orange[900],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!canAbsen) const SizedBox(height: 16),
                      // Buttons Container (Sticky at bottom)
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Clock In Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: canAbsen
                                    ? () => _recordAttendance('Masuk')
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF85E085),
                                  disabledBackgroundColor: Colors.grey[300],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Clock In',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: canAbsen
                                        ? Colors.white
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Clock Out Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: canAbsen
                                    ? () => _recordAttendance('Keluar')
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF645C),
                                  disabledBackgroundColor: Colors.grey[300],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Clock Out',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: canAbsen
                                        ? Colors.white
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                          ],
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

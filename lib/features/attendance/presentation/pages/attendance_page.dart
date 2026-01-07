import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
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
import '../../../../core/services/session_service.dart';
import '../../../../core/services/face_recognition_service.dart';
import '../../../../core/models/face_recognition_response.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late providers.AttendanceProvider _attendanceProvider;
  final FaceRecognitionService _faceService = FaceRecognitionService();
  entities.User? _currentUser;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    _initializeProvider();
    _loadUserData();
    _initializeCamera();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        _checkStatus();
      }
    });
  }

  void _initializeProvider() {
    // Initialize dependencies
    final locationService = services.LocationService();
    final dataSource = datasources.AttendanceRemoteDataSourceImpl(
      firestore: firestore.FirebaseFirestore.instance,
      locationService: locationService,
    );
    final repository = repositories.AttendanceRepositoryImpl(
      remoteDataSource: dataSource,
      sessionService: SessionService.instance,
    );

    _attendanceProvider = providers.AttendanceProvider(
      checkStatusUseCase: usecases.CheckAttendanceStatusUseCase(repository),
      recordAttendanceUseCase: usecases.RecordAttendanceUseCase(repository),
    );
  }

  Future<void> _loadUserData() async {
    final sessionService = SessionService.instance;
    await sessionService.init();
    final userModel = await sessionService.getSession();

    if (userModel != null && mounted && !_isDisposed) {
      setState(() {
        _currentUser = entities.User(
          uid: userModel.uid,
          email: userModel.email,
          fullName: userModel.fullName,
          nip: userModel.nip,
          faceDataBase64: userModel.faceDataBase64,
          role: userModel.role,
          isActive: userModel.isActive,
        );
      });
    }
  }

  Future<void> _checkStatus() async {
    await _attendanceProvider.checkStatus();
  }

  /// Capture foto dan validasi dengan Face Recognition API
  Future<FaceRecognitionResponse?> _captureAndValidateFace() async {
    if (!mounted || _isProcessing) return null;

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showError('Kamera belum siap');
      return null;
    }

    if (_cameraController!.value.isTakingPicture) return null;

    setState(() => _isProcessing = true);

    XFile? photo;
    File? imageFile;

    try {
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted || _cameraController == null) {
        throw Exception('Kamera tidak tersedia');
      }

      photo = await _cameraController!.takePicture().timeout(
        const Duration(seconds: 3),
        onTimeout: () => throw Exception('Timeout saat mengambil foto'),
      );

      imageFile = File(photo.path);

      if (!await imageFile.exists()) {
        throw Exception('File foto tidak ditemukan');
      }

      if (!mounted) return null;

      final response = await _faceService
          .validateAttendance(imageFile)
          .timeout(const Duration(seconds: 30));

      return FaceRecognitionResponse.fromJson(response);
    } catch (e) {
      if (mounted) {
        _showError(
          e.toString().contains('TimeoutException')
              ? 'Timeout: API terlalu lama merespon'
              : e.toString().contains('Timeout saat mengambil foto')
              ? 'Gagal mengambil foto, coba lagi'
              : 'Gagal memproses foto',
        );
      }
      return null;
    } finally {
      try {
        if (imageFile != null && await imageFile.exists()) {
          await imageFile.delete();
        }
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 200));

      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (_isDisposed) return;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty || _isDisposed) return;

      // Pilih front camera untuk face recognition
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // Dispose controller lama jika ada
      if (_cameraController != null) {
        await _cameraController?.dispose().catchError((_) {});
        _cameraController = null;
      }

      if (_isDisposed) return;

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg, // Prevent buffer overflow
      );

      await _cameraController!.initialize();

      if (mounted && !_isDisposed) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  @override
  void deactivate() {
    // Pause preview saat page tidak aktif
    _cameraController?.pausePreview().catchError((_) {});
    super.deactivate();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cameraController?.dispose().catchError((_) {});
    _cameraController = null;
    super.dispose();
  }

  Future<void> _recordAttendance(String type) async {
    if (_isProcessing) return;

    _showLoading('Memvalidasi wajah...');

    final faceResult = await _captureAndValidateFace();

    if (!mounted) return;

    Navigator.of(context).pop();

    if (faceResult == null) {
      _showError('Gagal mengambil atau memvalidasi foto');
      return;
    }

    final bool isFaceRecognized =
        faceResult.status == 'sukses' &&
        faceResult.dikenali == true &&
        faceResult.nama != null &&
        faceResult.nama != 'Tidak Dikenal' &&
        faceResult.nama!.trim().isNotEmpty;

    if (!isFaceRecognized) {
      if (faceResult.status == 'gagal') {
        _showError('Wajah tidak terdeteksi. Posisikan wajah dengan benar');
      } else if (faceResult.nama == 'Tidak Dikenal' ||
          faceResult.dikenali == false) {
        _showError('Wajah tidak terdaftar dalam database');
      } else {
        _showError('Validasi gagal. Silakan coba lagi');
      }
      return;
    }

    // Validasi: Pastikan wajah yang terdeteksi sesuai dengan akun yang login
    if (_currentUser == null) {
      _showError('Session tidak valid. Silakan login kembali');
      return;
    }

    // Ekstrak NIP dan Nama dari format API: "NIP_Nama_Angka"
    // Contoh: "5230411042_Ahmad Fata Dani Adnan_01" -> NIP: "5230411042", Nama: "Ahmad Fata Dani Adnan", Angka: "01"
    String extractedName = faceResult.nama!.trim();
    String? extractedNip;

    // Jika nama mengandung underscore, ambil NIP dan nama
    if (extractedName.contains('_')) {
      final parts = extractedName.split('_');
      if (parts.length >= 3) {
        // Bagian pertama adalah NIP
        extractedNip = parts[0];

        // Bagian tengah adalah nama
        if (parts.length == 3) {
          extractedName = parts[1];
        } else if (parts.length > 3) {
          // Jika lebih dari 3 bagian, gabungkan semua kecuali first dan last
          extractedName = parts.sublist(1, parts.length - 1).join('_');
        }
      }
    }

    // Normalisasi untuk perbandingan (case-insensitive & trim whitespace)
    final detectedName = extractedName.toLowerCase().trim();
    final loginName = _currentUser!.fullName.toLowerCase().trim();

    // Validasi Nama
    if (detectedName != loginName) {
      _showError(
        'Wajah tidak sesuai dengan akun login!\n'
        // 'Terdeteksi: $extractedName\n'
        'Akun login: ${_currentUser!.fullName}',
      );
      return;
    }

    // Validasi NIP (jika berhasil diekstrak)
    if (extractedNip != null) {
      final detectedNip = extractedNip.trim();
      final loginNip = _currentUser!.nip.trim();

      if (detectedNip != loginNip) {
        _showError(
          'NIP tidak sesuai dengan akun login!\n'
          // 'NIP Terdeteksi: $extractedNip\n'
          'NIP Akun: ${_currentUser!.nip}',
        );
        return;
      }
    }

    _showLoading('Menyimpan absensi...');

    final success = await _attendanceProvider.recordAttendance(type);

    if (!mounted) return;

    Navigator.of(context).pop();

    if (success) {
      _showSuccessDialog(
        type: type,
        userName: faceResult.nama!,
        similarity: ((1 - faceResult.jarakKemiripan!) * 100).toStringAsFixed(1),
      );
      await _checkStatus();
    } else {
      _showError(_attendanceProvider.errorMessage ?? 'Gagal merekam absensi');
    }
  }

  void _showLoading(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          margin: const EdgeInsets.all(40),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessDialog({
    required String type,
    required String userName,
    required String similarity,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Absensi Berhasil!', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Tipe', type),
            const Divider(),
            _buildDetailRow('Nama', userName),
            _buildDetailRow('Kemiripan', '$similarity%'),
            _buildDetailRow('Waktu', _formatTime(DateTime.now())),
            const Divider(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Presensi $type berhasil untuk $userName',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
                        child: RefreshIndicator(
                          onRefresh: _checkStatus,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  const SizedBox(height: 24),
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
                                onPressed: (canAbsen && !_isProcessing)
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
                                child: _isProcessing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Clock In',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: (canAbsen && !_isProcessing)
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
                                onPressed: (canAbsen && !_isProcessing)
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
                                child: _isProcessing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Clock Out',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: (canAbsen && !_isProcessing)
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

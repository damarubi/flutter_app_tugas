import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../../core/services/face_recognition_service.dart';
import '../../../../core/models/face_recognition_response.dart';

class FaceAttendancePage extends StatefulWidget {
  const FaceAttendancePage({super.key});

  @override
  State<FaceAttendancePage> createState() => _FaceAttendancePageState();
}

class _FaceAttendancePageState extends State<FaceAttendancePage> {
  final FaceRecognitionService _faceService = FaceRecognitionService();

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isLoading = false;
  bool _isConnected = false;
  FaceRecognitionResponse? _recognitionResult;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _checkConnection();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _showErrorNotification('Tidak ada kamera tersedia di perangkat');
        return;
      }

      // Pilih front camera (selfie)
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
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

        // Notifikasi kamera siap
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '📸 Kamera siap digunakan',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      _showErrorNotification('Error inisialisasi kamera: ${e.toString()}');
    }
  }

  Future<void> _checkConnection() async {
    final connected = await _faceService.testConnection();
    if (mounted) {
      setState(() {
        _isConnected = connected;
      });

      // Notifikasi status koneksi
      if (connected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cloud_done, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '🟢 API Terhubung - Siap untuk absensi',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        _showErrorNotification('API Terputus. Periksa koneksi atau server');
      }
    }
  }

  Future<void> _captureAndValidate() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showErrorNotification('Kamera belum siap. Tunggu sebentar...');
      return;
    }

    if (!_isConnected) {
      _showErrorNotification(
        'API tidak terhubung. Periksa koneksi internet Anda',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _recognitionResult = null;
    });

    try {
      // Capture foto
      final XFile photo = await _cameraController!.takePicture();
      final File imageFile = File(photo.path);

      // Langsung validasi ke API
      final response = await _faceService.validateAttendance(imageFile);
      final result = FaceRecognitionResponse.fromJson(response);

      if (mounted) {
        setState(() {
          _recognitionResult = result;
          _isLoading = false;
        });

        // Tampilkan notifikasi push berdasarkan hasil
        _showAttendanceNotification(result);

        // Tampilkan dialog hasil
        _showResultDialog(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Notifikasi error
        _showErrorNotification('Gagal memproses: ${e.toString()}');
      }
    }
  }

  void _showAttendanceNotification(FaceRecognitionResponse result) {
    Color bgColor;
    IconData icon;
    String message;

    if (result.isRecognized) {
      // Absensi BERHASIL
      bgColor = Colors.green;
      icon = Icons.check_circle;
      message = '✅ Absensi Berhasil! Selamat datang, ${result.nama}';
    } else if (!result.isFaceDetected) {
      // WAJAH TIDAK TERDETEKSI
      bgColor = Colors.orange;
      icon = Icons.face_retouching_off;
      message = '⚠️ Wajah tidak terdeteksi. Posisikan wajah dengan benar';
    } else {
      // WAJAH TIDAK TEREGISTRASI
      bgColor = Colors.red;
      icon = Icons.person_off;
      message = '❌ Wajah tidak terdaftar. Silakan registrasi terlebih dahulu';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
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
        backgroundColor: bgColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showErrorNotification(String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '🔴 Error: $errorMessage',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showResultDialog(FaceRecognitionResponse result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.isRecognized ? Icons.check_circle : Icons.error,
              color: result.isRecognized ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 10),
            Text(result.isRecognized ? 'Berhasil!' : 'Gagal'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.nama != null) ...[
              Text(
                'Nama: ${result.nama}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (result.jarakKemiripan != null) ...[
              Text(
                'Tingkat Kemiripan: ${(1 - result.jarakKemiripan!).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              result.isRecognized
                  ? 'Presensi berhasil dicatat'
                  : result.pesan ?? 'Wajah tidak dikenali',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (result.isRecognized) {
                // Reset untuk absensi berikutnya
                setState(() {
                  _recognitionResult = null;
                });
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi Face Recognition'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isConnected ? Icons.cloud_done : Icons.cloud_off,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            onPressed: _checkConnection,
            tooltip: _isConnected ? 'API Terhubung' : 'API Terputus',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          if (_isCameraInitialized && _cameraController != null)
            SizedBox.expand(child: CameraPreview(_cameraController!))
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Overlay UI
          SafeArea(
            child: Column(
              children: [
                // Status Connection
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: _isConnected
                        ? Colors.green.withOpacity(0.9)
                        : Colors.red.withOpacity(0.9),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isConnected ? Icons.check_circle : Icons.warning,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _isConnected ? 'API Terhubung' : 'API Terputus',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Guide Frame
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      'Posisikan wajah Anda\ndi dalam frame',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(blurRadius: 10.0, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Result Display
                if (_recognitionResult != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _recognitionResult!.isRecognized
                          ? Colors.green.withOpacity(0.9)
                          : Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _recognitionResult!.isRecognized
                              ? Icons.check_circle
                              : Icons.info,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        if (_recognitionResult!.nama != null)
                          Text(
                            _recognitionResult!.nama!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (_recognitionResult!.jarakKemiripan != null)
                          Text(
                            'Kemiripan: ${((1 - _recognitionResult!.jarakKemiripan!) * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Info Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '📸 Panduan Foto:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Wajah terlihat jelas\n• Pencahayaan cukup\n• Tidak pakai masker/kacamata\n• Posisi menghadap kamera',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Capture Button
                if (_isCameraInitialized)
                  Container(
                    margin: const EdgeInsets.only(bottom: 40),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _captureAndValidate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt, size: 28),
                                SizedBox(width: 10),
                                Text(
                                  'AMBIL FOTO & VALIDASI',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
              ],
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Memvalidasi wajah...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

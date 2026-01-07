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
  bool _isCapturing = false; // Lock untuk mencegah concurrent capture

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _checkConnection();
  }

  @override
  void dispose() {
    _cameraController?.dispose().catchError((e) {
      // Suppress error saat dispose
    });
    super.dispose();
  }

  @override
  void deactivate() {
    _cameraController?.pausePreview();
    super.deactivate();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          _showErrorNotification('Tidak ada kamera tersedia di perangkat');
        }
        return;
      }

      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      // Dispose controller lama jika ada
      await _cameraController?.dispose().catchError((_) {});

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium, // Medium untuk balance kualitas & performa
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        print('✅ Kamera berhasil diinisialisasi');
      }
    } catch (e) {
      if (mounted) {
        _showErrorNotification('Error inisialisasi kamera: ${e.toString()}');
      }
    }
  }

  Future<void> _checkConnection() async {
    final connected = await _faceService.testConnection();
    if (mounted) {
      setState(() {
        _isConnected = connected;
      });
    }
  }

  Future<void> _captureAndValidate() async {
    if (!mounted) return;

    // CRITICAL: Cegah concurrent capture
    if (_isCapturing || _isLoading) {
      print('⚠️ Capture sedang berlangsung, request diabaikan');
      return;
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showErrorNotification('Kamera belum siap');
      return;
    }

    if (_cameraController!.value.isTakingPicture) {
      print('⚠️ Kamera sedang mengambil gambar');
      return;
    }

    if (!_isConnected) {
      _showErrorNotification('API tidak terhubung');
      return;
    }

    // Set lock dan hide preview
    if (!mounted) return;
    setState(() {
      _isCapturing = true;
      _isLoading = true;
    });

    XFile? photo;
    File? imageFile;

    try {
      // Delay kecil untuk stabilkan buffer kamera
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted || _cameraController == null) {
        throw Exception('Kamera tidak tersedia');
      }

      print('📸 Mengambil foto...');

      // Capture dengan timeout yang lebih pendek
      photo = await _cameraController!.takePicture().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw Exception('Timeout saat mengambil foto');
        },
      );

      imageFile = File(photo.path);
      print('📁 Foto tersimpan: ${photo.path}');

      // Validasi file
      if (!await imageFile.exists()) {
        throw Exception('Gagal mengambil foto');
      }

      final fileSize = await imageFile.length();
      print('📊 Ukuran file: $fileSize bytes');

      if (fileSize < 1024) {
        throw Exception('Foto tidak valid (terlalu kecil)');
      }

      if (!mounted) {
        throw Exception('Widget tidak aktif');
      }

      print('🚀 Mengirim ke API...');

      // Kirim ke API dengan timeout
      final response = await _faceService
          .validateAttendance(imageFile)
          .timeout(const Duration(seconds: 30));

      final result = FaceRecognitionResponse.fromJson(response);

      print('✅ Response diterima: ${result.status}');

      if (!mounted) return;

      // Validasi ketat
      final bool isRecognized =
          result.status == 'sukses' &&
          result.dikenali == true &&
          result.nama != null &&
          result.nama != 'Tidak Dikenal';

      if (isRecognized) {
        // HANYA jika wajah dikenali, catat dan tampilkan success
        await _recordAttendance(result);
        _showAttendanceNotification(result);
        _showResultDialog(result);
      } else {
        // Wajah tidak dikenali atau error dari API
        if (result.status == 'gagal') {
          _showErrorNotification(
            'Wajah tidak terdeteksi. Posisikan wajah dengan benar',
          );
        } else if (result.status == 'error') {
          _showErrorNotification(result.pesan ?? 'Error dari server');
        } else {
          // Status sukses tapi tidak dikenali
          _showErrorNotification(
            'Wajah terdeteksi tapi tidak terdaftar: ${result.nama ?? "Tidak Dikenal"}',
          );
        }
      }
    } catch (e) {
      print('❌ Error capture: $e');
      if (mounted) {
        _showErrorNotification(
          e.toString().contains('TimeoutException')
              ? 'Timeout: API terlalu lama merespon'
              : e.toString().contains('Timeout saat mengambil foto')
              ? 'Gagal mengambil foto, coba lagi'
              : 'Gagal memproses: ${e.toString()}',
        );
      }
    } finally {
      // CLEANUP: Selalu hapus file dan reset lock
      try {
        if (imageFile != null && await imageFile.exists()) {
          await imageFile.delete();
          print('🗑️ File temporary dihapus');
        }
      } catch (e) {
        print('⚠️ Gagal hapus file: $e');
      }

      // Delay kecil untuk reset buffer kamera
      await Future.delayed(const Duration(milliseconds: 200));

      // RESET LOCK - CRITICAL!
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isCapturing = false;
        });
        print('🔓 Lock direset, kamera siap');
      }
    }
  }

  /// Catat absensi ke database (HANYA jika wajah dikenali)
  Future<void> _recordAttendance(FaceRecognitionResponse result) async {
    try {
      final attendanceData = {
        'nama': result.nama,
        'timestamp': DateTime.now().toIso8601String(),
        'jarak_kemiripan': result.jarakKemiripan,
        'status': 'hadir',
      };

      // TODO: Simpan ke Firebase/database
      // await FirebaseFirestore.instance.collection('attendance').add(attendanceData);
    } catch (e) {
      print('❌ Gagal menyimpan: $e');
    }
  }

  void _showAttendanceNotification(FaceRecognitionResponse result) {
    Color bgColor;
    IconData icon;
    String message;

    // Cek status dari API
    if (result.status == 'gagal') {
      // WAJAH TIDAK TERDETEKSI oleh MTCNN
      bgColor = Colors.orange;
      icon = Icons.face_retouching_off;
      message = '⚠️ Wajah tidak terdeteksi. Posisikan wajah dengan benar';
    } else if (result.status == 'error') {
      // ERROR dari server
      bgColor = Colors.red.shade700;
      icon = Icons.error_outline;
      message = '🔴 Error: ${result.pesan ?? "Terjadi kesalahan pada server"}';
    } else if (result.status == 'sukses') {
      // Sukses detect wajah, cek apakah dikenali
      if (result.dikenali == true) {
        // WAJAH DIKENALI - Absensi BERHASIL
        bgColor = Colors.green;
        icon = Icons.check_circle;
        message =
            '✅ Absensi Berhasil! Selamat datang, ${result.nama ?? "User"}';
      } else {
        // WAJAH TERDETEKSI TAPI TIDAK TEREGISTRASI
        bgColor = Colors.red;
        icon = Icons.person_off;
        message =
            '❌ Wajah tidak terdaftar. Nama: ${result.nama ?? "Tidak Dikenal"}';
      }
    } else {
      // Status tidak dikenal
      bgColor = Colors.grey;
      icon = Icons.help_outline;
      message = '❓ Status tidak dikenal: ${result.status}';
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
    // Tentukan apakah benar-benar berhasil
    final bool isActualSuccess =
        result.status == 'sukses' && result.dikenali == true;

    showDialog(
      context: context,
      barrierDismissible: false, // Paksa user klik OK
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isActualSuccess ? Icons.check_circle : Icons.error,
              color: isActualSuccess ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isActualSuccess ? 'Absensi Berhasil!' : 'Absensi Gagal',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status detail
            _buildDetailRow('Status API', result.status),
            const Divider(),

            if (result.nama != null) ...[_buildDetailRow('Nama', result.nama!)],

            if (result.jarakKemiripan != null) ...[
              _buildDetailRow(
                'Jarak',
                result.jarakKemiripan!.toStringAsFixed(4),
              ),
              _buildDetailRow(
                'Kemiripan',
                '${((1 - result.jarakKemiripan!) * 100).toStringAsFixed(1)}%',
              ),
              _buildDetailRow(
                'Threshold',
                result.jarakKemiripan! < 0.8
                    ? '✅ Pass (< 0.8)'
                    : '❌ Fail (≥ 0.8)',
              ),
            ],

            _buildDetailRow(
              'Dikenali',
              result.dikenali == true ? '✅ Ya' : '❌ Tidak',
            ),

            const Divider(),

            // Pesan final
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActualSuccess
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActualSuccess ? Colors.green : Colors.red,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActualSuccess
                        ? '✅ ABSENSI TERCATAT'
                        : '❌ ABSENSI DITOLAK',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isActualSuccess
                          ? Colors.green.shade900
                          : Colors.red.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isActualSuccess
                        ? 'Presensi berhasil untuk ${result.nama}'
                        : result.pesan ??
                              'Wajah tidak dikenali atau tidak terdaftar',
                    style: TextStyle(
                      fontSize: 13,
                      color: isActualSuccess
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
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
            width: 100,
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      onPopInvoked: (didPop) async {
        if (!didPop) return;
        await _cameraController?.dispose().catchError((_) {});
      },
      child: Scaffold(
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

                  // Capture Button
                  if (_isCameraInitialized)
                    Container(
                      margin: const EdgeInsets.only(bottom: 40),
                      child: ElevatedButton(
                        onPressed:
                            (_isLoading ||
                                _isCapturing ||
                                !_isCameraInitialized)
                            ? null
                            : _captureAndValidate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                        ),
                        child: _isLoading || _isCapturing
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
      ),
    );
  }
}

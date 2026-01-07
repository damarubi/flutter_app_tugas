import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'dart:convert';

class FaceRecognitionService {
  // URL ngrok API
  static const String baseUrl =
      'https://napiform-baffling-rosalina.ngrok-free.dev';

  /// Validasi presensi wajah dengan mengirim foto ke API
  /// [imageFile] - File foto yang akan divalidasi
  /// Returns JSON response dari API
  Future<Map<String, dynamic>> validateAttendance(File imageFile) async {
    try {
      print('\n🔵 [API REQUEST START]');
      print('📍 URL: $baseUrl/presensi');
      print('📄 File: ${imageFile.path}');

      // Validasi file exists
      if (!await imageFile.exists()) {
        throw Exception('File tidak ditemukan: ${imageFile.path}');
      }

      final fileSize = await imageFile.length();
      print(
        '📊 File size: $fileSize bytes (${(fileSize / 1024).toStringAsFixed(2)} KB)',
      );

      // Validasi ukuran file (min 1KB, max 10MB)
      if (fileSize < 1024) {
        throw Exception('File terlalu kecil (<1KB), mungkin corrupt');
      }
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('File terlalu besar (>10MB)');
      }

      final uri = Uri.parse('$baseUrl/presensi');

      // Buat multipart request dengan timeout
      var request = http.MultipartRequest('POST', uri);

      // Header penting untuk ngrok
      request.headers.addAll({
        'ngrok-skip-browser-warning': 'true',
        'User-Agent': 'FaceRecognitionApp/1.0',
      });

      print('📤 Headers: ${request.headers}');

      // Baca file sebagai bytes untuk validasi
      final bytes = await imageFile.readAsBytes();
      print('📦 Bytes read: ${bytes.length}');

      // Cek magic bytes untuk JPEG (FF D8 FF)
      if (bytes.length < 3) {
        throw Exception('File terlalu kecil untuk menjadi gambar valid');
      }

      final isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
      final isPng =
          bytes.length >= 4 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47;

      print(
        '🖼️  Image format: ${isJpeg
            ? "JPEG"
            : isPng
            ? "PNG"
            : "UNKNOWN"}',
      );

      if (!isJpeg && !isPng) {
        print('⚠️  Warning: File bukan JPEG/PNG, tapi tetap dikirim');
      }

      // Tambahkan file ke request dengan content-type yang tepat
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'photo.jpg',
        contentType: http_parser.MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);
      print('📎 File attached: photo.jpg');
      print('   - Length: ${multipartFile.length} bytes');
      print('   - ContentType: ${multipartFile.contentType}');
      print('   - Field name: ${multipartFile.field}');
      print('   - Filename: ${multipartFile.filename}');

      print('🚀 Mengirim request ke API...');
      final startTime = DateTime.now();

      // Kirim request dengan timeout 30 detik (proses AI butuh waktu)
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final duration = DateTime.now().difference(startTime);
      print('⏱️  Response time: ${duration.inMilliseconds}ms');

      // Konversi response ke string
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      // Parse JSON response
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        // Validasi struktur response
        if (jsonResponse is! Map<String, dynamic>) {
          print('❌ Response format tidak valid');
          throw Exception('Response format tidak valid');
        }

        // Cek apakah ada field 'status'
        if (!jsonResponse.containsKey('status')) {
          print('❌ Response tidak memiliki field status');
          throw Exception('Response tidak memiliki field status');
        }

        print('✅ [API REQUEST SUCCESS]\n');
        return jsonResponse;
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('❌ Body: ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ [API REQUEST FAILED]');
      print('❌ Error Type: ${e.runtimeType}');
      print('❌ Error: $e\n');
      rethrow;
    }
  }

  /// Test koneksi ke API
  Future<bool> testConnection() async {
    try {
      print('\n🔍 ===== TESTING API CONNECTION =====');
      print('📍 URL: $baseUrl/');
      print('🕐 Time: ${DateTime.now().toIso8601String()}');

      final response = await http
          .get(
            Uri.parse('$baseUrl/'),
            headers: {
              'ngrok-skip-browser-warning': 'true',
              'User-Agent': 'FaceRecognitionApp/1.0',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Headers: ${response.headers}');
      print(
        '📥 Response Body (first 200 chars): ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}',
      );

      // Accept 200, 404, or 405 as "connected"
      // 200 = OK
      // 404 = endpoint tidak ada tapi server hidup
      // 405 = method not allowed tapi server hidup
      final isConnected =
          response.statusCode == 200 ||
          response.statusCode == 404 ||
          response.statusCode == 405;

      print(
        isConnected
            ? '✅ API CONNECTION: SUCCESS (Status ${response.statusCode})'
            : '❌ API CONNECTION: FAILED (Status ${response.statusCode})',
      );
      print('===================================\n');

      return isConnected;
    } catch (e, stackTrace) {
      print('\n❌ ===== API CONNECTION FAILED =====');
      print('❌ Error Type: ${e.runtimeType}');
      print('❌ Error: $e');
      print('❌ StackTrace: $stackTrace');
      print('===================================\n');
      return false;
    }
  }
}

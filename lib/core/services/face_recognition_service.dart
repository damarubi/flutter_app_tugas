import 'dart:io';
import 'package:http/http.dart' as http;
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
      final uri = Uri.parse('$baseUrl/presensi');

      // Buat multipart request
      var request = http.MultipartRequest('POST', uri);

      // Tambahkan file ke request
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Kirim request
      final streamedResponse = await request.send();

      // Konversi response ke string
      final response = await http.Response.fromStream(streamedResponse);

      // Parse JSON response
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gagal validasi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Test koneksi ke API
  Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

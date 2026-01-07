import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_tugas/core/models/face_recognition_response.dart';

void main() {
  group('FaceRecognitionResponse Model Tests', () {
    test('Should parse successful recognition response', () {
      // Arrange
      final json = {
        'status': 'sukses',
        'nama': 'John Doe',
        'jarak_kemiripan': 0.456,
        'dikenali': true,
      };

      // Act
      final response = FaceRecognitionResponse.fromJson(json);

      // Assert
      expect(response.status, 'sukses');
      expect(response.nama, 'John Doe');
      expect(response.jarakKemiripan, 0.456);
      expect(response.dikenali, true);
      expect(response.isSuccess, true);
      expect(response.isRecognized, true);
    });

    test('Should parse failed recognition response', () {
      // Arrange
      final json = {
        'status': 'sukses',
        'nama': 'Tidak Dikenal',
        'jarak_kemiripan': 0.95,
        'dikenali': false,
      };

      // Act
      final response = FaceRecognitionResponse.fromJson(json);

      // Assert
      expect(response.status, 'sukses');
      expect(response.nama, 'Tidak Dikenal');
      expect(response.isRecognized, false);
    });

    test('Should parse face not detected response', () {
      // Arrange
      final json = {'status': 'gagal', 'pesan': 'Wajah tidak terdeteksi'};

      // Act
      final response = FaceRecognitionResponse.fromJson(json);

      // Assert
      expect(response.status, 'gagal');
      expect(response.pesan, 'Wajah tidak terdeteksi');
      expect(response.isFaceDetected, false);
    });

    test('Should convert to JSON correctly', () {
      // Arrange
      final response = FaceRecognitionResponse(
        status: 'sukses',
        nama: 'Test User',
        jarakKemiripan: 0.5,
        dikenali: true,
      );

      // Act
      final json = response.toJson();

      // Assert
      expect(json['status'], 'sukses');
      expect(json['nama'], 'Test User');
      expect(json['jarak_kemiripan'], 0.5);
      expect(json['dikenali'], true);
    });
  });
}

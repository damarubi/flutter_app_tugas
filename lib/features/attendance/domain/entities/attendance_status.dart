class AttendanceStatus {
  final bool isInOfficeArea;
  final bool hasFaceData;
  final double? distanceInMeters;
  final String message;

  AttendanceStatus({
    required this.isInOfficeArea,
    required this.hasFaceData,
    this.distanceInMeters,
    required this.message,
  });

  bool get canAttend => isInOfficeArea && hasFaceData;

  String get distanceMessage {
    if (distanceInMeters == null) return 'Mengecek jarak...';
    if (distanceInMeters! <= 100) {
      return 'Anda berada di dalam area kantor.';
    }
    return 'Anda berada ${distanceInMeters!.toStringAsFixed(2)} meter di luar area kantor.';
  }

  String get statusMessage {
    if (!isInOfficeArea) {
      return 'Anda tidak berada di area kantor.';
    } else if (!hasFaceData) {
      return 'Silahkan daftarkan wajah Anda di halaman Akun terlebih dahulu.';
    } else {
      return 'Verifikasi berhasil! Anda dapat melakukan absensi.';
    }
  }
}

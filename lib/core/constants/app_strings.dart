class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'Absensi Pegawai';

  // Auth
  static const String login = 'Login';
  static const String register = 'Daftar Akun';
  static const String logout = 'Keluar';
  static const String nip = 'NIP';
  static const String password = 'Password';
  static const String confirmPassword = 'Konfirmasi Password';
  static const String fullName = 'Nama Lengkap';
  static const String welcome = 'Selamat Datang!';
  static const String loginToContinue = 'Masuk untuk melanjutkan';
  static const String registerSuccess = 'Pendaftaran berhasil!';
  static const String loginSuccess = 'Login berhasil!';
  static const String alreadyHaveAccount = 'Sudah punya akun?';
  static const String dontHaveAccount = 'Belum punya akun?';

  // Errors
  static const String errorGeneric = 'Terjadi kesalahan. Silakan coba lagi.';
  static const String errorUserNotFound =
      'Pengguna tidak ditemukan untuk NIP tersebut.';
  static const String errorWrongPassword = 'Password salah.';
  static const String errorWeakPassword = 'Password terlalu lemah.';
  static const String errorEmailInUse = 'Akun sudah terdaftar untuk NIP ini.';
  static const String errorPasswordMismatch = 'Password tidak cocok.';

  // Navigation
  static const String home = 'Beranda';
  static const String attendance = 'Presensi';
  static const String profile = 'Akun';

  // Attendance
  static const String checkIn = 'Masuk';
  static const String checkOut = 'Pulang';
  static const String attendanceHistory = 'Riwayat Absensi';
  static const String noAttendanceData = 'Belum ada data absensi.';

  // Face Recognition
  static const String faceRecognition = 'Face Recognition';
  static const String registerFaceRecognition = 'Registrasi Face Recognition';
  static const String faceDataSaved = 'Data Face Recognition Telah Tersimpan';
  static const String noFaceData = 'Belum Ada Data Face Recognition Tersimpan';

  // Profile
  static const String personalData = 'DATA DIRI';
  static const String attendanceData = 'DATA ABSENSI';

  // Common
  static const String loading = 'Memuat...';
  static const String save = 'Simpan';
  static const String cancel = 'Batal';
  static const String done = 'Selesai';
  static const String next = 'Selanjutnya';
  static const String back = 'Kembali';
}

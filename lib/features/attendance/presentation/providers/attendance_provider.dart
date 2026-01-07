import 'package:flutter/foundation.dart';
import '../../domain/entities/attendance_status.dart' as entities;
import '../../domain/usecases/check_attendance_status_usecase.dart' as usecases;
import '../../domain/usecases/record_attendance_usecase.dart' as usecases;
import '../../domain/repositories/attendance_repository.dart' as repositories;

class AttendanceProvider extends ChangeNotifier {
  final usecases.CheckAttendanceStatusUseCase checkStatusUseCase;
  final usecases.RecordAttendanceUseCase recordAttendanceUseCase;
  final repositories.AttendanceRepository repository;

  AttendanceProvider({
    required this.checkStatusUseCase,
    required this.recordAttendanceUseCase,
    required this.repository,
  });

  entities.AttendanceStatus? _attendanceStatus;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInOfficeArea = false;
  bool _hasFaceData = false;
  String _statusMessage = 'Memuat...';
  String? _distanceMessage;

  entities.AttendanceStatus? get attendanceStatus => _attendanceStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get canAttend => _attendanceStatus?.canAttend ?? false;
  bool get isInOfficeArea => _isInOfficeArea;
  bool get hasFaceData => _hasFaceData;
  String get statusMessage => _statusMessage;
  String? get distanceMessage => _distanceMessage;

  Future<void> checkStatus() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _attendanceStatus = await checkStatusUseCase();
      _isInOfficeArea = _attendanceStatus?.isInOfficeArea ?? false;
      _hasFaceData = _attendanceStatus?.hasFaceData ?? false;

      // Update status message
      if (_isInOfficeArea && _hasFaceData) {
        _statusMessage = 'Anda dapat melakukan absensi';
      } else if (!_isInOfficeArea && !_hasFaceData) {
        _statusMessage =
            'Anda berada di luar area kantor dan belum melakukan face recognition';
      } else if (!_isInOfficeArea) {
        _statusMessage = 'Anda berada di luar area kantor';
      } else {
        _statusMessage = 'Anda belum melakukan face recognition';
      }

      // Update distance message
      if (_attendanceStatus?.distanceInMeters != null) {
        final distance = _attendanceStatus!.distanceInMeters!;
        _distanceMessage =
            'Jarak dari kantor: ${distance.toStringAsFixed(0)} meter';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _statusMessage = 'Gagal memeriksa status';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> recordAttendance(String type) async {
    try {
      await recordAttendanceUseCase(type: type);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getTodayAttendance() async {
    return await repository.getTodayAttendance();
  }
}

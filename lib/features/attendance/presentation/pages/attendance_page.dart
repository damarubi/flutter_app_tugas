import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../providers/attendance_provider.dart' as providers;
import '../../data/datasources/attendance_remote_datasource.dart'
    as datasources;
import '../../data/repositories/attendance_repository_impl.dart'
    as repositories;
import '../../domain/usecases/check_attendance_status_usecase.dart' as usecases;
import '../../domain/usecases/record_attendance_usecase.dart' as usecases;
import '../../../../shared/services/location_service.dart' as services;

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late providers.AttendanceProvider _attendanceProvider;

  @override
  void initState() {
    super.initState();
    _initializeProvider();
    _checkStatus();
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

  Future<void> _checkStatus() async {
    await _attendanceProvider.checkStatus();
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
            appBar: AppBar(title: const Text('Presensi'), centerTitle: true),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: provider.isLoading
                          ? const CircularProgressIndicator()
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  canAbsen ? Icons.check_circle : Icons.error,
                                  color: canAbsen ? Colors.green : Colors.red,
                                  size: 80,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  provider.statusMessage,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: canAbsen
                                        ? Colors.green[800]
                                        : Colors.red[800],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (provider.distanceMessage != null)
                                  Text(
                                    provider.distanceMessage!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: canAbsen
                                          ? Colors.grey[600]
                                          : Colors.red[400],
                                    ),
                                  ),
                                const SizedBox(height: 24),
                                if (canAbsen)
                                  Column(
                                    children: [
                                      ElevatedButton(
                                        onPressed: () =>
                                            _recordAttendance('Masuk'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          minimumSize: const Size(
                                            double.infinity,
                                            50,
                                          ),
                                        ),
                                        child: const Text(
                                          'Clock In',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () =>
                                            _recordAttendance('Keluar'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          minimumSize: const Size(
                                            double.infinity,
                                            50,
                                          ),
                                        ),
                                        child: const Text(
                                          'Clock Out',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

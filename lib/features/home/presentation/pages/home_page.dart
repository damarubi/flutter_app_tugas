// import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:geolocator/geolocator.dart';
import '../providers/home_provider.dart' as providers;
import '../../data/datasources/home_remote_datasource.dart' as datasources;
import '../../data/repositories/home_repository_impl.dart' as repositories;
import '../../domain/usecases/get_dashboard_data_usecase.dart' as usecases;
import '../../../../shared/services/location_service.dart' as services;
import 'package:intl/intl.dart';
import '../../../../map_widget.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime selectedDate = DateTime.now();
  int selectedOfficeIndex = 0;
  Position? currentPosition;
  bool isInsideZone = false;

  late providers.HomeProvider _homeProvider;

  @override
  void initState() {
    super.initState();
    _initializeProvider();
    _checkLocationPermissionAndGetPosition();
  }

  void _initializeProvider() {
    final locationService = services.LocationService();
    final remoteDataSource = datasources.HomeRemoteDataSourceImpl(
      firebaseAuth: firebase_auth.FirebaseAuth.instance,
      firestoreInstance: firestore.FirebaseFirestore.instance,
      locationService: locationService,
    );
    final repository = repositories.HomeRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );
    final getDashboardUseCase = usecases.GetDashboardDataUseCase(repository);

    _homeProvider = providers.HomeProvider(
      getDashboardDataUseCase: getDashboardUseCase,
    );

    _homeProvider.loadDashboardData();
  }

  Future<void> _checkLocationPermissionAndGetPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      currentPosition = position;
      _checkIfInsideGeofence(position);
    });
  }

  void _checkIfInsideGeofence(Position position) {
    bool insideAnyZone = false;

    for (var office in AppConstants.officeLocations) {
      final location = office['location'] as LatLng;
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        location.latitude,
        location.longitude,
      );

      if (distance <= AppConstants.geofenceRadius) {
        insideAnyZone = true;
        break;
      }
    }

    setState(() {
      isInsideZone = insideAnyZone;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('User not logged in'));
    }

    final selectedDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    return provider.ChangeNotifierProvider<providers.HomeProvider>.value(
      value: _homeProvider,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildSearchBar(),
              ),
              _buildMapSection(),
              const SizedBox(height: 24),
              _buildAttendanceStatusSection(user, selectedDateStr),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 20,
            color: Colors.blue,
            margin: const EdgeInsets.only(right: 4),
          ),
          Container(
            width: 4,
            height: 30,
            color: Colors.blue,
            margin: const EdgeInsets.only(right: 4),
          ),
          Container(
            width: 4,
            height: 20,
            color: Colors.blue,
            margin: const EdgeInsets.only(right: 8),
          ),
          const Text(
            'Absen.in',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
    );
  }

  Widget _buildMapSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: MapWidget(
                    locations: AppConstants.officeLocations
                        .map((office) => office['location'] as LatLng)
                        .toList(),
                    officeNames: AppConstants.officeLocations
                        .map((office) => office['name'] as String)
                        .toList(),
                    currentPosition: currentPosition,
                    geofenceRadius: AppConstants.geofenceRadius,
                    selectedOfficeIndex: selectedOfficeIndex,
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isInsideZone ? Icons.check_circle : Icons.info,
                    color: isInsideZone ? Colors.blue : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isInsideZone
                          ? 'You are inside the allowed zone'
                          : 'You are outside the allowed zone',
                      style: TextStyle(
                        color: isInsideZone ? Colors.black87 : Colors.grey[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => _showOfficeSelector(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5E6D3),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                AppConstants.officeLocations[selectedOfficeIndex]['name']
                    as String,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.search, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  void _showOfficeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Pilih Zona Absen',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ...AppConstants.officeLocations.asMap().entries.map((entry) {
                final index = entry.key;
                final office = entry.value;
                final isSelected = index == selectedOfficeIndex;

                return ListTile(
                  leading: Icon(
                    Icons.business,
                    color: isSelected ? const Color(0xFFFFA778) : Colors.grey,
                  ),
                  title: Text(
                    office['name'] as String,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? Colors.orange : Colors.black87,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.orange)
                      : null,
                  onTap: () {
                    setState(() {
                      selectedOfficeIndex = index;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceStatusSection(
    firebase_auth.User user,
    String selectedDateStr,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Laporan Absensi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<firestore.DocumentSnapshot>(
              stream: firestore.FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('attendance')
                  .doc(selectedDateStr)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final attendanceData =
                    snapshot.data?.data() as Map<String, dynamic>?;
                final clockInTime = attendanceData?['MasukTime'] as String?;
                final clockOutTime = attendanceData?['KeluarTime'] as String?;

                String statusText;
                Color statusColor;

                if (clockInTime == null && clockOutTime == null) {
                  statusText = 'Belum Clock-in';
                  statusColor = const Color(0xFFFF645C);
                } else if (clockInTime != null && clockOutTime == null) {
                  statusText = 'Belum Clock-out';
                  statusColor = const Color(0xFFFF645C);
                } else {
                  statusText = 'Sudah Absen';
                  statusColor = const Color(0xFF85E085);
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                DateFormat('dd MMM yyyy').format(selectedDate),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 0, 0, 0),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              statusText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (clockInTime == null && clockOutTime == null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE5E5),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.cancel,
                              color: Color(0xFFFF645C),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Anda belum absen hari ini',
                                style: TextStyle(
                                  color: Color(0xFFFF645C),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildClockButton(
                            label: 'Clock In',
                            time: clockInTime ?? '--:--',
                            isActive: clockInTime != null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildClockButton(
                            label: 'Clock Out',
                            time: clockOutTime ?? '--:--',
                            isActive: clockOutTime != null,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClockButton({
    required String label,
    required String time,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

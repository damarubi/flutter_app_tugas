import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart' as provider;
import 'package:intl/intl.dart';
import '../../../../core/services/session_service.dart';
import '../providers/history_provider.dart' as providers;
import '../../data/datasources/history_remote_datasource.dart' as datasources;
import '../../data/repositories/history_repository_impl.dart' as repositories;
import '../../domain/usecases/get_attendance_history_usecase.dart' as usecases;
import '../../domain/usecases/get_monthly_stats_usecase.dart' as usecases;

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late providers.HistoryProvider _historyProvider;

  @override
  void initState() {
    super.initState();
    _initializeProvider();
  }

  void _initializeProvider() {
    final dataSource = datasources.HistoryRemoteDataSourceImpl(
      firestore: FirebaseFirestore.instance,
    );
    final repository = repositories.HistoryRepositoryImpl(
      remoteDataSource: dataSource,
      sessionService: SessionService(),
    );

    _historyProvider = providers.HistoryProvider(
      getAttendanceHistoryUseCase: usecases.GetAttendanceHistoryUseCase(
        repository,
      ),
      getMonthlyStatsUseCase: usecases.GetMonthlyStatsUseCase(repository),
    );

    _historyProvider.loadMonthlyStats();
  }

  @override
  void dispose() {
    _historyProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return provider.ChangeNotifierProvider.value(
      value: _historyProvider,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Riwayat Absensi',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: provider.Consumer<providers.HistoryProvider>(
          builder: (context, historyProvider, _) {
            return Column(
              children: [
                _buildMonthSelector(historyProvider),
                _buildStatsCards(historyProvider),
                _buildCalendar(historyProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMonthSelector(providers.HistoryProvider provider) {
    final monthYear = DateFormat(
      'MMMM yyyy',
      'id_ID',
    ).format(provider.selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Periode',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5E6D3),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  monthYear,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showMonthPicker(provider),
                  child: const Icon(Icons.arrow_drop_down, size: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(providers.HistoryProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFADFFCA),
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
                children: [
                  Text(
                    '${provider.stats['hadir'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Hadir',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color.fromARGB(107, 255, 100, 92),
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
                children: [
                  Text(
                    '${provider.stats['tidakHadir'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tidak Hadir',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(providers.HistoryProvider provider) {
    return Expanded(
      child: StreamBuilder(
        stream: provider.getAttendanceHistoryStream(),
        builder: (context, snapshot) {
          final attendanceRecords = snapshot.data ?? [];

          // Create a set of days with clock_in for highlighting
          final attendanceDays = <int>{};
          for (var record in attendanceRecords) {
            if (record.isClockIn) {
              attendanceDays.add(record.timestamp.day);
            }
          }

          return Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
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
              children: [
                _buildWeekDayHeaders(),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildCalendarGrid(
                    provider.selectedDate,
                    attendanceDays,
                  ),
                ),
                const SizedBox(height: 12),
                _buildLegend(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeekDayHeaders() {
    const weekDays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid(DateTime selectedDate, Set<int> attendanceDays) {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      0,
    );
    final daysInMonth = lastDayOfMonth.day;

    // Get first day of week (1 = Monday, 7 = Sunday)
    int firstWeekday = firstDayOfMonth.weekday;

    // Get days from previous month to fill the first week
    final prevMonthDays = firstWeekday - 1;
    final lastDayOfPrevMonth = DateTime(
      selectedDate.year,
      selectedDate.month,
      0,
    ).day;

    final now = DateTime.now();
    final isCurrentMonth =
        selectedDate.year == now.year && selectedDate.month == now.month;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 42, // 6 weeks
      itemBuilder: (context, index) {
        if (index < prevMonthDays) {
          // Previous month days
          final day = lastDayOfPrevMonth - prevMonthDays + index + 1;
          return _buildCalendarDay(day.toString(), isOtherMonth: true);
        } else if (index < prevMonthDays + daysInMonth) {
          // Current month days
          final day = index - prevMonthDays + 1;
          final isToday = isCurrentMonth && day == now.day;
          final hasAttendance = attendanceDays.contains(day);
          final isPastDay = isCurrentMonth ? day < now.day : true;
          final isAbsent = isPastDay && !hasAttendance;

          return _buildCalendarDay(
            day.toString(),
            isToday: isToday,
            hasAttendance: hasAttendance,
            isAbsent: isAbsent,
          );
        } else {
          // Next month days
          final day = index - prevMonthDays - daysInMonth + 1;
          return _buildCalendarDay(day.toString(), isOtherMonth: true);
        }
      },
    );
  }

  Widget _buildCalendarDay(
    String day, {
    bool isToday = false,
    bool hasAttendance = false,
    bool isAbsent = false,
    bool isOtherMonth = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isToday ? const Color(0xFFFFF9C4) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isToday
            ? Border.all(color: const Color(0xFFFDD835), width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isOtherMonth ? Colors.black26 : Colors.black87,
            ),
          ),
          if (hasAttendance) ...[
            const SizedBox(height: 4),
            Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ] else if (isAbsent) ...[
            const SizedBox(height: 4),
            Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFF44336),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Hadir', const Color(0xFF4CAF50)),
        const SizedBox(width: 16),
        _buildLegendItem('Tidak Hadir', const Color(0xFFF44336)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }

  void _showMonthPicker(providers.HistoryProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'Pilih Bulan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final monthName = DateFormat(
                      'MMM',
                      'id_ID',
                    ).format(DateTime(2025, month));
                    final isSelected = provider.selectedDate.month == month;

                    return GestureDetector(
                      onTap: () {
                        provider.changeMonth(provider.selectedDate.year, month);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2196F3)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            monthName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

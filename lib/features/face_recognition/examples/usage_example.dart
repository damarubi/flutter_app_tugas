import 'package:flutter/material.dart';
import 'package:flutter_app_tugas/features/face_recognition/presentation/pages/face_attendance_page.dart';

/// Example implementation untuk menambahkan Face Attendance ke aplikasi existing
///
/// Contoh 1: Tambahkan sebagai menu item
class HomePageExample extends StatelessWidget {
  const HomePageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.face),
            title: const Text('Absensi Face Recognition'),
            subtitle: const Text('Tap untuk melakukan absensi'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FaceAttendancePage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Contoh 2: Tambahkan sebagai FAB (Floating Action Button)
class MainScreenExample extends StatelessWidget {
  const MainScreenExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Main Screen')),
      body: const Center(child: Text('Your main content here')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FaceAttendancePage()),
          );
        },
        icon: const Icon(Icons.face_retouching_natural),
        label: const Text('Absensi'),
        tooltip: 'Face Recognition Attendance',
      ),
    );
  }
}

/// Contoh 3: Tambahkan sebagai button di dashboard
class DashboardExample extends StatelessWidget {
  const DashboardExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildFeatureCard(
              context,
              icon: Icons.face,
              title: 'Face Recognition',
              subtitle: 'Absensi',
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FaceAttendancePage(),
                ),
              ),
            ),
            // Add more feature cards here...
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Contoh 4: Direct usage dengan custom button
class CustomUsageExample extends StatelessWidget {
  const CustomUsageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate to face attendance page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FaceAttendancePage(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.face, size: 28),
              SizedBox(width: 10),
              Text(
                'Absensi dengan Face Recognition',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Contoh 5: Integration dengan Bottom Navigation
class BottomNavExample extends StatefulWidget {
  const BottomNavExample({super.key});

  @override
  State<BottomNavExample> createState() => _BottomNavExampleState();
}

class _BottomNavExampleState extends State<BottomNavExample> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Center(child: Text('Home Page')),
    const Center(child: Text('History Page')),
    const FaceAttendancePage(), // Face Recognition page
    const Center(child: Text('Profile Page')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.face), label: 'Absensi'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

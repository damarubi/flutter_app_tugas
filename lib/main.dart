import 'package:flutter/material.dart';
import 'profile_page.dart'; // Halaman profil dari kode sebelumnya
import 'presensi_page.dart'; // Halaman presensi yang baru

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 2; // Indeks awal diatur ke Presensi

  // Daftar halaman yang akan ditampilkan
  static final List<Widget> _widgetOptions = <Widget>[
    const Center(child: Text('Halaman Beranda')), // Placeholder
    const Center(child: Text('Halaman Info')), // Placeholder
    PresensiPage(),
    const Center(child: Text('Halaman Courses')), // Placeholder
    ProfilePage(), // Halaman Akun/Profil
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Widget untuk Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFFE8DDCF),
        border: Border(
          top: BorderSide(
            color: Colors.black,
            width: 2.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_outlined, 'Beranda', 0),
          _buildNavItem(Icons.notifications_none_outlined, 'Info', 1),
          _buildNavItem(Icons.qr_code_scanner_outlined, 'Presensi', 2),
          _buildNavItem(Icons.book_outlined, 'Courses', 3),
          _buildNavItem(Icons.account_circle_outlined, 'Akun', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String text, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.black : Colors.grey[700],
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.black : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
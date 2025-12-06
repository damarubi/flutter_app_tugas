import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import intl
import 'core/constants/app_routes.dart';
import 'core/services/session_service.dart'; // Import SessionService
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/main/presentation/pages/main_page.dart'; // Pastikan path ini benar
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Date Formatting
  await initializeDateFormatting('id_ID', null);

  // 2. Initialize Session Service (PENTING!)
  final sessionService = SessionService();
  await sessionService.init();

  // 3. Cek apakah user sudah login
  final bool isLoggedIn = await sessionService.isSessionExists();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absensi App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      // 4. Tentukan halaman awal berdasarkan status login
      initialRoute: isLoggedIn ? AppRoutes.main : AppRoutes.login,
      routes: {
        AppRoutes.login: (context) => const LoginPage(),
        AppRoutes.register: (context) => const RegisterPage(),
        AppRoutes.main: (context) => const MainPage(),
      },
    );
  }
}

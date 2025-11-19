import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app_tugas/core/theme/app_theme.dart';
import 'package:flutter_app_tugas/core/constants/app_strings.dart';
import 'package:flutter_app_tugas/config/routes/app_router.dart';
import 'package:flutter_app_tugas/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_app_tugas/features/home/presentation/pages/main_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      onGenerateRoute: AppRouter.generateRoute,
      // Use StreamBuilder to check authentication status
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            // If user is logged in, show main screen with BottomNavigationBar
            return const MainScreen();
          }
          // If not logged in, redirect to login page
          return const LoginPage();
        },
      ),
    );
  }
}

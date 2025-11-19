import 'package:flutter/material.dart';
import 'package:flutter_app_tugas/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_app_tugas/features/auth/presentation/pages/register_page.dart';
import 'package:flutter_app_tugas/features/home/presentation/pages/main_screen.dart';
import 'package:flutter_app_tugas/features/face_recognition/presentation/pages/face_recognition_page.dart';
import 'package:flutter_app_tugas/features/face_recognition/presentation/pages/camera_view_page.dart';
import 'package:flutter_app_tugas/features/face_recognition/presentation/pages/success_page.dart';
import '../../core/constants/app_routes.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());

      case AppRoutes.main:
        return MaterialPageRoute(builder: (_) => const MainScreen());

      case AppRoutes.faceRecognition:
        return MaterialPageRoute(builder: (_) => const FaceRecognitionPage());

      case AppRoutes.cameraView:
        return MaterialPageRoute(builder: (_) => const CameraViewPage());

      case AppRoutes.success:
        return MaterialPageRoute(builder: (_) => const SuccessPage());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}

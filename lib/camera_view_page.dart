import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app_tugas/success_page.dart';

class CameraViewPage extends StatefulWidget {
  const CameraViewPage({super.key});

  @override
  State<CameraViewPage> createState() => _CameraViewPageState();
}

class _CameraViewPageState extends State<CameraViewPage> {
  final ImagePicker _picker = ImagePicker();
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _takeSelfieAndSave() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 50,
      );

      if (image == null) {
        setState(() {
          _isLoading = false;
        });
        return; // User canceled
      }

      await _saveImageToFirestore(File(image.path));
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengambil foto: $e';
        _isLoading = false;
      });
      print('Error taking or saving image: $e');
    }
  }

  Future<void> _saveImageToFirestore(File imageFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Pengguna tidak login.';
        _isLoading = false;
      });
      return;
    }

    try {
      // Read the image file as bytes
      final bytes = await imageFile.readAsBytes();
      // Convert the bytes to a base64 string
      final base64Image = base64Encode(bytes);

      // Save the base64 string to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'faceDataBase64': base64Image,
        'faceRegistrationTimestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isLoading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SuccessPage()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal menyimpan foto: $e';
        _isLoading = false;
      });
      print('Error saving image to Firestore: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _takeSelfieAndSave();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Foto Selfie'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey, width: 2),
                ),
                child: const FlutterLogo(size: 150),
              ),
              const SizedBox(height: 30),
              const Text(
                'Posisikan Wajah Anda Berada Didalam Frame.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Silahkan Kedipkan Mata (simulasi)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 30),
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
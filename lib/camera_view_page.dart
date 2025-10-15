import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'success_page.dart';

class CameraViewPage extends StatefulWidget {
  const CameraViewPage({super.key});

  @override
  State<CameraViewPage> createState() => _CameraViewPageState();
}

class _CameraViewPageState extends State<CameraViewPage> {
  final ImagePicker _picker = ImagePicker();
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _takeSelfie() async {
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

      await _uploadImageToFirebase(File(image.path));
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengambil foto: $e';
        _isLoading = false;
      });
      print('Error taking or uploading image: $e');
    }
  }

  Future<void> _uploadImageToFirebase(File imageFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Pengguna tidak login.';
        _isLoading = false;
      });
      return;
    }

    try {
      final storageRef = FirebaseStorage.instance.ref().child('face_data/${user.uid}.jpg');
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});

      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Save the download URL to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'faceDataUrl': downloadUrl,
        'faceRegistrationTimestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isLoading = false;
      });

      // Navigate to the success page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SuccessPage()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengunggah foto: $e';
        _isLoading = false;
      });
      print('Error uploading image to Firebase: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _takeSelfie();
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
                child: const Icon(Icons.person, size: 150, color: Colors.grey),
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
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/session_service.dart';
import 'camera_view_page.dart';

class FaceRecognitionPage extends StatelessWidget {
  const FaceRecognitionPage({super.key});

  Future<bool> _checkFaceData() async {
    final sessionService = SessionService.instance;
    await sessionService.init();
    final user = await sessionService.getSession();
    if (user == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists || doc.data() == null) return false;

    final data = doc.data()!;
    return data['faceDataBase64'] != null &&
        data['faceDataBase64'].toString().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Recognition'), centerTitle: true),
      body: FutureBuilder<bool>(
        future: _checkFaceData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final hasFaceData = snapshot.data ?? false;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasFaceData)
                    Column(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 100,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Data Face Recognition Telah Tersimpan',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Anda dapat memperbarui data wajah Anda kapan saja.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        const FlutterLogo(size: 120),
                        const SizedBox(height: 20),
                        const Text(
                          'Belum Ada Data Face Recognition Tersimpan',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Anda dapat melakukan registrasi face recognition untuk mempermudah anda dalam melakukan absensi',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CameraViewPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'REGISTRASI FACE RECOGNITION',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ],
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

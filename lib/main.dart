import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flavorgen/screens/Get Started/getstarted.dart'; // Import de GetStartedPage
import 'package:camera/camera.dart'; // Import de la bibliothèque de caméra

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Erreur lors de l\'initialisation de Firebase : $e');
  }

  // Récupère les caméras disponibles
  final cameras = await availableCameras();

  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Authentification',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const GetStartedPage(), // Affiche l'écran Get Started au début
    );
  }
}

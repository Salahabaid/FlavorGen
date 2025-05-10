import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flavorgen/screens/Get Started/getstarted.dart'; // Import de GetStartedPage
import 'package:camera/camera.dart'; // Import de la bibliothèque de caméra
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:flavorgen/screens/Recipe/recipe_detail_screen.dart';

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

class MyApp extends StatefulWidget {
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;
  Uri? _pendingInitialUri;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();

    // Gère les liens reçus quand l'app est déjà ouverte
    _linkSub = _appLinks.uriLinkStream.listen((Uri? uri) {
      _handleIncomingLink(uri);
    });

    // Gère le lien initial (quand l'app démarre via un lien)
    _handleInitialLink();
  }

  Future<void> _handleInitialLink() async {
    final uri = await _appLinks.getInitialLink();
    if (uri != null) {
      setState(() {
        _pendingInitialUri = uri;
      });
    }
  }

  void _handleIncomingLink(Uri? uri) {
    if (uri != null &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments[0] == 'recipes') {
      final recipeId = uri.pathSegments[1];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeLoaderScreen(recipeId: recipeId),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Navigation automatique si un lien initial est présent
    if (_pendingInitialUri != null &&
        _pendingInitialUri!.pathSegments.isNotEmpty &&
        _pendingInitialUri!.pathSegments[0] == 'recipes') {
      final recipeId = _pendingInitialUri!.pathSegments[1];
      // On efface le pending pour éviter la boucle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _pendingInitialUri = null;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeLoaderScreen(recipeId: recipeId),
          ),
        );
      });
    }

    return MaterialApp(
      title: 'Authentification',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const GetStartedPage(),
    );
  }
}

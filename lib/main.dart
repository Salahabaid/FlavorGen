import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flavorgen/screens/Get Started/getstarted.dart';
import 'package:camera/camera.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:flavorgen/screens/Recipe/recipe_detail_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Erreur lors de l\'initialisation de Firebase : $e');
  }
  await _initFCM();

  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

Future<void> _initFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();
  String? token = await messaging.getToken();
  print('FCM Token: $token');
  final user = FirebaseAuth.instance.currentUser;
  if (user != null && token != null) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }
}

// Obtenir et afficher le token FCM
Future<void> printFcmToken() async {
  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $token");
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

    // Écoute les notifications push reçues pendant l'utilisation de l'app
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(notification.title ?? 'Notification reçue')),
        );
      }
      print('Notification reçue: ${notification?.title}');
    });
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

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flavorgen/models/ingredient.dart';
import 'package:flavorgen/services/yolo_service.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  final YoloService _yoloService = YoloService();
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isPermissionGranted = false;
  List<Ingredient> _detectedIngredients = [];
  Timer? _detectionTimer;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionsAndInitCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detectionTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Gérer les changements d'état de l'application (mise en arrière-plan, etc.)
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCameraController(cameraController.description);
    }
  }

  Future<void> _checkPermissionsAndInitCamera() async {
    final status = await Permission.camera.request();
    setState(() {
      _isPermissionGranted = status.isGranted;
    });

    if (_isPermissionGranted) {
      await _initializeCameras();
    } else {
      _showPermissionDeniedDialog();
    }
  }

  Future<void> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _initializeCameraController(_cameras[0]);
        _startPeriodicDetection();
      } else {
        _showErrorDialog('Aucune caméra disponible');
      }
    } on CameraException catch (e) {
      _showErrorDialog('Erreur d\'initialisation: ${e.description}');
    }
  }

  Future<void> _initializeCameraController(
    CameraDescription cameraDescription,
  ) async {
    final CameraController controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _cameraController = controller;

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } on CameraException catch (e) {
      _showErrorDialog('Erreur caméra: ${e.description}');
    }
  }

  void _startPeriodicDetection() {
    // Effectuer la détection toutes les 3 secondes
    _detectionTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isProcessing && _isInitialized && mounted) {
        _captureAndDetectIngredients();
      }
    });
  }

  Future<void> _captureAndDetectIngredients() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Capture d'image
      final XFile imageFile = await _cameraController!.takePicture();

      // Préparation de l'image pour YOLOv8
      final File file = File(imageFile.path);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image != null) {
        // Traitement de l'image avec YOLOv8
        final detectedIngredients = await _yoloService.detectIngredientsInImage(
          image,
        );

        if (mounted) {
          setState(() {
            _detectedIngredients = detectedIngredients;
            _isProcessing = false;
          });
          if (detectedIngredients.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Aucun ingrédient détecté. Essayez à nouveau avec un fond clair et un bon éclairage.',
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur de traitement: $e')));
      }
    }
  }

  void _finishDetection() {
    Navigator.pop(context, _detectedIngredients);
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Autorisation requise'),
            content: const Text(
              'Veuillez autoriser l\'accès à votre caméra pour utiliser cette fonctionnalité.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Fermer'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Paramètres'),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Erreur'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Fermer'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      body:
          _isPermissionGranted
              ? _buildCameraView()
              : _buildPermissionDeniedView(),
    );
  }

  Widget _buildCameraView() {
    if (!_isInitialized || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    final scale = 1 / (_cameraController!.value.aspectRatio * deviceRatio);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Vue caméra
        Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: CameraPreview(_cameraController!),
        ),

        // Overlay pour les ingrédients détectés
        if (_detectedIngredients.isNotEmpty)
          Positioned(
            top: 48,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ingrédients détectés:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _detectedIngredients.map((ingredient) {
                          return Chip(
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.8),
                            label: Text(
                              '${ingredient.name} (${(ingredient.confidence! * 100).toStringAsFixed(0)}%)',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ),

        // Indicateur de chargement pendant le traitement
        if (_isProcessing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Analyzing...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Boutons de contrôle
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Bouton d'annulation
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(150, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Annuler'),
              ),

              // Bouton pour capturer manuellement
              FloatingActionButton(
                onPressed: _captureAndDetectIngredients,
                backgroundColor: Colors.white,
                child: const Icon(Icons.camera_alt, color: Colors.black),
              ),

              // Bouton pour confirmer les ingrédients
              ElevatedButton(
                onPressed:
                    _detectedIngredients.isNotEmpty ? _finishDetection : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(150, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Confirmer'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_photography, size: 80, color: Colors.white54),
          const SizedBox(height: 24),
          const Text(
            'Autorisation caméra requise',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _checkPermissionsAndInitCamera,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Autoriser l\'accès'),
          ),
        ],
      ),
    );
  }
}

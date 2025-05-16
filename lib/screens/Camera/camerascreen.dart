import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flavorgen/models/ingredient.dart';
import 'package:flavorgen/services/yolo_service.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final YoloService _yoloService = YoloService();
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isPermissionGranted = false;
  List<Ingredient> _detectedIngredients = [];
  String? _lastCapturedImagePath;

  // Define an accent color for the screen
  final Color _accentColor = Colors.tealAccent[400]!;
  final Color _darkBackgroundColor = Colors.grey[900]!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionsAndInitCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
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
      } else {
        _showErrorDialog('Aucune caméra disponible');
      }
    } on CameraException catch (e) {
      _showErrorDialog('Erreur d\'initialisation: ${e.description}');
    }
  }

  Future<void> _initializeCameraController(CameraDescription cameraDescription) async {
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

  Future<void> _captureAndDetectIngredients() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      final directory = await getApplicationDocumentsDirectory();
      final String newPath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(imageFile.path).copy(newPath);

      setState(() {
        _lastCapturedImagePath = newPath;
      });

      final File file = File(newPath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image != null) {
        final detectedIngredients = await _yoloService.detectIngredientsInImage(image);
        if (mounted) {
          setState(() {
            _detectedIngredients = detectedIngredients;
            _isProcessing = false;
          });
        }
      } else {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de traitement: $e')));
    }
  }

  Future<void> _pickImageFromGallery() async {
    print("Attempting to pick image from gallery...");
    final picker = ImagePicker();
    XFile? pickedFile;

    try {
      pickedFile = await picker.pickImage(source: ImageSource.gallery);
    } catch (e) {
      print("Error picking image from gallery: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'ouverture de la galerie: ${e.toString()}')),
        );
      }
      return; // Exit if picker fails
    }
    
    if (pickedFile != null) {
      print("Picked file path: ${pickedFile.path}");
    } else {
      print("No file picked from gallery.");
    }

    if (pickedFile != null) {
      final String filePath = pickedFile.path;

      setState(() {
        _isProcessing = true;
        _lastCapturedImagePath = filePath;
        _detectedIngredients.clear();
      });

      try {
        final bytes = await File(filePath).readAsBytes();
        final image = img.decodeImage(bytes);

        if (image != null) {
          print("Image decoded successfully. Processing with YOLO...");
          final List<Ingredient> detectedIngredientsResult = await _yoloService.detectIngredientsInImage(image);
          
          if (mounted) {
            setState(() {
              _detectedIngredients = detectedIngredientsResult;
              _isProcessing = false;
            });

            if (detectedIngredientsResult.isEmpty) {
              print("No ingredients detected by YOLO service.");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Aucun ingrédient n\'a été détecté dans l\'image.')),
              );
            } else {
              print("Detected ingredients: ${detectedIngredientsResult.map((i) => i.name).join(', ')}");
            }
          }
        } else {
          print("Failed to decode image.");
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erreur: Impossible de lire le format de l\'image sélectionnée.')),
            );
          }
        }
      } catch (e) {
        print("Error processing image or with YOLO service: $e");
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de l\'analyse de l\'image: ${e.toString()}')),
          );
        }
      }
    } else {
      print("No image selected from gallery (pickedFile was null).");
      // Optionally, show a message if the user cancels
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Aucune image sélectionnée.')),
      //   );
      // }
    }
  }

  void _resetDetection() {
    setState(() {
      _lastCapturedImagePath = null;
      _detectedIngredients.clear();
    });
  }

  void _finishDetection() {
    Navigator.pop(context, _detectedIngredients);
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Autorisation requise'),
        content: const Text('Veuillez autoriser l\'accès à la caméra.'),
        actions: [
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
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackgroundColor,
      appBar: AppBar(
        title: const Text('Détecter les Ingrédients'),
        backgroundColor: _darkBackgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isPermissionGranted ? _buildCameraView() : _buildPermissionDeniedView(),
      ),
    );
  }

  Widget _buildCameraView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          flex: 3, 
          child: _buildImagePreviewOrCamera(),
        ),
        // Section 2: Detected Ingredients or Loading (Animated)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: _isProcessing
              ? Padding(
                  key: const ValueKey('loading'), // Key for AnimatedSwitcher
                  padding: const EdgeInsets.all(16.0),
                  child: _buildLoadingIndicator(),
                )
              : _detectedIngredients.isNotEmpty
                  ? Padding(
                      key: const ValueKey('ingredients'), // Key for AnimatedSwitcher
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _buildIngredientsDisplay(), 
                    )
                  : SizedBox(key: const ValueKey('emptySpace'), height: MediaQuery.of(context).size.height * 0.1), // Placeholder when no results and not loading
        ),
        // Spacer if no ingredients and not processing, but image is shown
        // if (!_isProcessing && _detectedIngredients.isEmpty && _lastCapturedImagePath != null)
        //   const SizedBox(height: 20), // Adjusted by AnimatedSwitcher's empty space
          
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildActionButtons(),
        ),
      ],
    );
  }

  Widget _buildImagePreviewOrCamera() {
    if (_lastCapturedImagePath != null) {
      // Display the captured or picked image
      return Container(
        margin: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accentColor.withOpacity(0.5), width: 2),
          image: DecorationImage(
            image: FileImage(File(_lastCapturedImagePath!)),
            fit: BoxFit.contain,
          ),
        ),
      );
    } else if (_cameraController != null && _cameraController!.value.isInitialized && _isInitialized) {
      // Display camera preview only if no image is captured yet
      return Container(
        margin: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[700]!, width: 1)
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: CameraPreview(_cameraController!),
        ),
      );
    } else if (_isPermissionGranted) {
      // Show loading indicator while camera is initializing
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    } else {
      // Fallback for permission denied, though parent widget should handle this
      return const Center(child: Text("Accès caméra requis", style: TextStyle(color: Colors.white)));
    }
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: _accentColor),
          const SizedBox(height: 20),
          Text('Analyse en cours...', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
  
  Widget _buildIngredientsDisplay() {
     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Important for Column inside AnimatedSwitcher
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 12.0, top: 8.0),
            child: Text(
              'Ingrédients Détectés:',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          LimitedBox(
            maxHeight: MediaQuery.of(context).size.height * 0.25, // Limit height of the list
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _detectedIngredients.length,
              itemBuilder: (context, index) {
                final ingredient = _detectedIngredients[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  color: Colors.grey[800],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _accentColor.withOpacity(0.8),
                          child: Text(
                            (ingredient.confidence! * 100).toStringAsFixed(0) + '%',
                            style: TextStyle(fontSize: 11, color: _darkBackgroundColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ingredient.name.capitalize(), // Capitalize first letter
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                        // Optional: Icon for more actions or details
                        // Icon(Icons.more_vert, color: Colors.white54),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
  }
  
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround, // Ensures spacing
      children: [
        if (_lastCapturedImagePath == null) ...[
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Photo'),
              onPressed: _isProcessing ? null : () => _showImageSourceActionSheet(context), // Disable if processing
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: _darkBackgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
              ),
            ),
          ),
          const SizedBox(width: 16), // Spacing between buttons
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Galerie'),
              onPressed: _isProcessing ? null : () => _showImageSourceActionSheet(context), // Disable if processing
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: _darkBackgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
              ),
            ),
          ),
        ] else ...[
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reprendre'),
              onPressed: _isProcessing ? null : _resetDetection, // Disable if processing
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
              ),
            ),
          ),
          if (_detectedIngredients.isNotEmpty)
           ...[
            const SizedBox(width: 16), // Spacing between buttons
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Confirmer'),
                onPressed: _isProcessing ? null : _finishDetection, // Disable if processing
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: _darkBackgroundColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                ),
              ),
            ),
           ]
        ],
      ],
    );
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.camera_alt_rounded, color: _accentColor, size: 32),
                title: Text(
                  'Prendre une photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _captureAndDetectIngredients();
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                tileColor: Colors.grey[850],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(color: Colors.white24, thickness: 1, height: 1),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_rounded, color: _accentColor, size: 32),
                title: Text(
                  'Importer depuis la galerie',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                tileColor: Colors.grey[850],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_photography, size: 80, color: Colors.white54),
            const SizedBox(height: 24),
            const Text(
              'Autorisation caméra requise',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Pour détecter les ingrédients, veuillez autoriser l\'accès à la caméra dans les paramètres de votre téléphone.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              ),
              onPressed: () async {
                final status = await Permission.camera.request();
                setState(() {
                  _isPermissionGranted = status.isGranted;
                });
                if (status.isGranted) {
                  _initializeCameras();
                } else if (status.isPermanentlyDenied || status.isRestricted) {
                   openAppSettings(); // Guide user to settings if permanently denied
                }
              },
              child: Text('Autoriser l\'accès', style: TextStyle(color: _darkBackgroundColor)),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper extension for String capitalization
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return "";
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}

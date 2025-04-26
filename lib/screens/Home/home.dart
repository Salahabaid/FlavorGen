// main.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Get available cameras
  final cameras = await availableCameras();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FlavorGen',
      theme: ThemeData(
        primaryColor: const Color(0xFF1FCC79),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Poppins',
      ),
      home: FlavorGenApp(cameras: cameras),
    );
  }
}

class FlavorGenApp extends StatefulWidget {
  final List<CameraDescription> cameras;

  const FlavorGenApp({Key? key, required this.cameras}) : super(key: key);

  @override
  _FlavorGenAppState createState() => _FlavorGenAppState();
}

class _FlavorGenAppState extends State<FlavorGenApp> {
  String activeTab = 'scan';
  String? capturedImagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildStatusBar(),
            _buildLogo(),
            _buildActionButtons(),
            Expanded(
              child: activeTab == 'scan' ? _buildScanTab() : _buildManualTab(),
            ),
            _buildGenerateButton(),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Icon(Icons.signal_cellular_4_bar, size: 18, color: Colors.black),
          SizedBox(width: 4),
          Icon(Icons.wifi, size: 18, color: Colors.black),
          SizedBox(width: 4),
          Icon(Icons.battery_full, size: 18, color: Colors.black),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Flavor",
            style: TextStyle(
              color: Color(0xFF230B34),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 24,
            height: 24,
            child: CustomPaint(painter: LeafIconPainter()),
          ),
          const SizedBox(width: 8),
          const Text(
            "Gen",
            style: TextStyle(color: Color(0xFF9FA5C0), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          _buildActionButton(
            'scan',
            Icons.camera_alt_outlined,
            'Scan Ingredients',
          ),
          const SizedBox(width: 16),
          _buildActionButton('manual', Icons.search, 'Manual Entry'),
        ],
      ),
    );
  }

  Widget _buildActionButton(String tab, IconData icon, String label) {
    final isActive = activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activeTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
            border: isActive ? Border.all(color: Colors.grey.shade200) : null,
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? const Color(0xFF1FCC79) : Colors.black,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? const Color(0xFF1FCC79) : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: _checkPermissionsAndOpenCamera,
            child: Container(
              margin: const EdgeInsets.only(top: 32),
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child:
                  capturedImagePath != null
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(capturedImagePath!),
                          fit: BoxFit.cover,
                        ),
                      )
                      : const Center(
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _checkPermissionsAndOpenCamera,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1FCC79),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              minimumSize: const Size(double.infinity, 56),
            ),
            child: const Text(
              'Scan Ingredients',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search ingredients...',
              hintStyle: const TextStyle(color: Color(0xFF9FA5C0)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(32),
                borderSide: const BorderSide(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 64),
          const Text(
            'Your Ingredients',
            style: TextStyle(
              color: Color(0xFF3E5481),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No ingredients added yet.',
            style: TextStyle(color: Color(0xFF9FA5C0)),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1FCC79),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          minimumSize: const Size(double.infinity, 56),
        ),
        child: const Text('Generate Recipe', style: TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: activeTab == 'scan' ? 0 : 1,
      onTap: (index) {
        setState(() {
          activeTab = index == 0 ? 'scan' : 'manual';
        });
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Scan'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Manual'),
      ],
    );
  }

  Future<void> _checkPermissionsAndOpenCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _openCamera();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission caméra refusée')),
      );
    }
  }

  void _openCamera() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(cameras: widget.cameras),
        ),
      );

      if (result != null) {
        setState(() {
          capturedImagePath = result;
        });
      }
    } catch (e) {
      // Affiche une erreur si la caméra ne peut pas être ouverte
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ouverture de la caméra : $e'),
        ),
      );
    }
  }
}

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    if (widget.cameras.isNotEmpty) {
      _cameraController = CameraController(
        widget.cameras[0], // Utilise la première caméra disponible
        ResolutionPreset.high,
      );
      _cameraController!
          .initialize()
          .then((_) {
            if (!mounted) return;
            setState(() {});
          })
          .catchError((e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Erreur lors de l\'initialisation de la caméra : $e',
                ),
              ),
            );
          });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: CameraPreview(_cameraController!),
    );
  }
}

class LeafIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF1FCC79)
          ..style = PaintingStyle.fill;

    final path =
        Path()
          ..moveTo(size.width * 0.5, 0)
          ..quadraticBezierTo(
            0,
            size.height * 0.5,
            size.width * 0.5,
            size.height,
          )
          ..quadraticBezierTo(
            size.width,
            size.height * 0.5,
            size.width * 0.5,
            0,
          )
          ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

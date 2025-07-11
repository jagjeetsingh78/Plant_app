import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_page.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MaterialApp(
    home: PermissionCheckScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class PermissionCheckScreen extends StatefulWidget {
  const PermissionCheckScreen({Key? key}) : super(key: key);

  @override
  State<PermissionCheckScreen> createState() => _PermissionCheckScreenState();
}

class _PermissionCheckScreenState extends State<PermissionCheckScreen> {
  bool _loading = true;
  String _message = "Checking permissions...";

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
  var status = await Permission.camera.status;

  if (status.isGranted) {
    await _navigateToCamera();
  } else {
    var result = await Permission.camera.request();
    if (result.isGranted) {
      await _navigateToCamera();
    } else if (result.isPermanentlyDenied) {
      setState(() {
        _loading = false;
        _message = "Permission permanently denied. Please enable it from settings.";
      });

      await openAppSettings(); // ✅ Correct way to handle permanently denied
    } else {
      setState(() {
        _loading = false;
        _message = "Camera permission denied. Please allow to proceed.";
      });
    }
  }
}

  Future<void> _navigateToCamera() async {
  try {
    cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() {
        _loading = false;
        _message = "No cameras available on this device";
      });
      return;
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage(camera: cameras.first)),
    );
  } catch (e) {
    setState(() {
      _loading = false;
      _message = "Failed to access camera: ${e.toString()}";
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_message, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _checkCameraPermission,
                    child: const Text("Try Again"),
                  ),
                ],
              ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../services/tflite_services.dart';

class HomePage extends StatefulWidget {
  final CameraDescription camera;
  const HomePage({required this.camera, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late CameraController _controller;
  late Future<void> _initializeController;
  String? _prediction;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeController = _controller.initialize();
    TFLiteService().loadModel();
  }

  Future<void> _classifyImage(File image) async {
    try {
      setState(() => _prediction = "🔍 Processing...");
      final results = await TFLiteService().classify(image);
      setState(() => _prediction =
          "${results[0].label} (${(results[0].confidence * 100).toStringAsFixed(1)}%)");
    } catch (e) {
      setState(() => _prediction = "❌ Error: ${e.toString()}");
    }
  }

  Future<void> _takePicture() async {
    try {
      await _initializeController;
      final image = await _controller.takePicture();
      final file = File(image.path);
      await _classifyImage(file);
    } catch (e) {
      debugPrint("❌ Camera error: $e");
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final file = File(picked.path);
        await _classifyImage(file);
      }
    } catch (e) {
      debugPrint("❌ Gallery error: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🌿 Plant Doctor')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: _initializeController,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          if (_prediction != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _prediction!,
                style: const TextStyle(fontSize: 20),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _pickFromGallery,
            child: const Icon(Icons.photo_library),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _takePicture,
            child: const Icon(Icons.camera),
          ),
        ],
      ),
    );
  }
}

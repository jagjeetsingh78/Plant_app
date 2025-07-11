import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  TFLiteService._internal();
  static final TFLiteService _instance = TFLiteService._internal();
  factory TFLiteService() => _instance;

  late final Interpreter _interpreter;      // set ONLY once
  late final List<String> _labels;          // set ONLY once

  bool _ready = false;
  bool _initializing = false;

  // ─────────── public API ───────────
  Future<void> loadModel() async {
    if (_ready || _initializing) return;
    _initializing = true;

    try {
      // 1. make sure the model file is in the APK
      await _ensureAsset('assets/models/model.tflite',
          '❌ model.tflite missing. Check pubspec.yaml.');

      // 2. build interpreter (CPU first; delegate can be added later)
      final Interpreter interp = await Interpreter.fromAsset(
        'assets/models/model.tflite',
        options: InterpreterOptions()..threads = 4,
      );

      // 3. load labels
      final List<String> labels = (await rootBundle.loadString('assets/labels.txt'))
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      // 4. verify label count
      final int modelClasses = interp.getOutputTensor(0).shape.last;
      if (modelClasses != labels.length) {
        throw Exception('Label count (${labels.length}) ≠ model classes ($modelClasses).');
      }

      // 5. now—and only now—assign to late finals
      _interpreter = interp;
      _labels      = labels;
      _ready       = true;

      debugPrint('✅ Interpreter ready  '
          '${_interpreter.getInputTensor(0).shape} → '
          '${_interpreter.getOutputTensor(0).shape}');
    } finally {
      _initializing = false;
    }
  }

  Future<List<ClassificationResult>> classify(File file, {int topK = 3}) async {
    if (!_ready) await loadModel();

    final img.Image? image = img.decodeImage(await file.readAsBytes());
    if (image == null) throw Exception('Invalid image');

    final int size = _interpreter.getInputTensor(0).shape[1];
    final input    = _preprocess(image, size);

    final outShape = _interpreter.getOutputTensor(0).shape;
    final output   =
        List.filled(outShape.reduce((a, b) => a * b), 0.0).reshape(outShape);

    _interpreter.run(input, output);
    return _topK(output[0] as List<double>, topK);
  }

  // ─────────── helpers ───────────
  Future<void> _ensureAsset(String path, String err) async {
    try {
      await rootBundle.load(path);
    } catch (_) {
      throw Exception(err);
    }
  }

  List _preprocess(img.Image src, int size) {
    final img.Image resized = img.copyResize(src, width: size, height: size);
    final Float32List data  = Float32List(size * size * 3);
    int i = 0;
    for (final p in resized) {
      data[i++] = p.r / 255.0;
      data[i++] = p.g / 255.0;
      data[i++] = p.b / 255.0;
    }
    return data.reshape([1, size, size, 3]);
  }

  List<ClassificationResult> _topK(List<double> logits, int k) {
    final list = List.generate(
      logits.length,
      (i) => ClassificationResult(label: _labels[i], confidence: logits[i]),
    )..sort((a, b) => b.confidence.compareTo(a.confidence));
    return list.take(k).toList();
  }
}

class ClassificationResult {
  final String label;
  final double confidence;
  const ClassificationResult({required this.label, required this.confidence});
}

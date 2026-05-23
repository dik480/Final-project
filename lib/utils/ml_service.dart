import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class MLService {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  Future<void> initialize() async {
    if (_isModelLoaded) return;
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/mobilenet_v2.tflite');
      _isModelLoaded = true;
      debugPrint('MobileNetV2 model loaded successfully.');
    } catch (e) {
      debugPrint('Failed to load MobileNetV2 model: $e');
    }
  }

  /// Extracts a 1280-element feature vector from the image file.
  Future<List<double>?> getFeatureVector(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return _getFeatureVectorFromBytes(bytes);
    } catch (e) {
      debugPrint('Error reading image file: $e');
      return null;
    }
  }

  /// Extracts a 1280-element feature vector from raw image bytes.
  Future<List<double>?> getFeatureVectorFromBytes(Uint8List bytes) async {
    return _getFeatureVectorFromBytes(bytes);
  }

  Future<List<double>?> _getFeatureVectorFromBytes(Uint8List bytes) async {
    if (!_isModelLoaded || _interpreter == null) {
      await initialize();
      if (!_isModelLoaded) return null;
    }

    try {
      // 1. Read and decode image
      final img.Image? decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return null;

      // 2. Resize to 224x224 (expected input size for MobileNetV2)
      final img.Image resizedImage = img.copyResize(decodedImage, width: 224, height: 224);

      // 3. Normalize pixels to [-1, 1] as expected by MobileNetV2 float models
      // Float32 format: [1, 224, 224, 3]
      var input = List.generate(
        1,
        (i) => List.generate(
          224,
          (y) => List.generate(
            224,
            (x) {
              final pixel = resizedImage.getPixel(x, y);
              // MobileNetV2 normalization: (value / 127.5) - 1.0
              return [
                (pixel.r / 127.5) - 1.0,
                (pixel.g / 127.5) - 1.0,
                (pixel.b / 127.5) - 1.0,
              ];
            },
          ),
        ),
      );

      // 4. Output tensor: [1, 1280] for feature vector
      var output = List.generate(1, (i) => List.filled(1280, 0.0));

      // 5. Run inference
      _interpreter!.run(input, output);

      // Return the 1280-element list
      return output[0];
    } catch (e) {
      debugPrint('Error getting feature vector: $e');
      return null;
    }
  }

  /// Calculates cosine similarity between two feature vectors.
  /// Returns a value between -1.0 and 1.0 (1.0 means exact match).
  double calculateCosineSimilarity(List<dynamic> vecADyn, List<dynamic> vecBDyn) {
    if (vecADyn.length != vecBDyn.length || vecADyn.isEmpty) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < vecADyn.length; i++) {
      double valA = (vecADyn[i] as num).toDouble();
      double valB = (vecBDyn[i] as num).toDouble();
      dotProduct += valA * valB;
      normA += valA * valA;
      normB += valB * valB;
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}

// Global instance
final mlService = MLService();

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flavorgen/models/ingredient.dart';
import 'dart:math' as math;
import 'dart:typed_data';

class YoloService {
  static final YoloService _instance = YoloService._internal();
  factory YoloService() => _instance;
  YoloService._internal();

  Interpreter? _interpreter;
  bool _isInitialized = false;
  List<String> _labels = [];

  static final Map<String, int> ingredientIds = {
    "apple": 9003,
    "onion": 11282,
    "tomato": 11529,
    "garlic": 11215,
    "carrot": 11124,
    "banana": 9040,
    "chicken": 5006,
    "egg": 1123,
    "potato": 11352,
    "mushroom": 11260,
    "broccoli": 11090,
    "cucumber": 11205,
    "lemon": 9150,
    "orange": 9200,
    "bell_pepper": 11821,
  };

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final labelsData = await rootBundle.loadString(
        'assets/models/labels.txt',
      );
      _labels = labelsData.split('\n');

      final options =
          InterpreterOptions()
            ..threads = 4
            ..useNnApiForAndroid = true;

      _interpreter = await Interpreter.fromAsset(
        'assets/models/yolo11n_float16.tflite',
        options: options,
      );

      _isInitialized = true;
    } catch (e) {
      print('Erreur d\'initialisation: $e');
      _isInitialized = false;
    }
  }

  Float32List _preprocessImage(img.Image image) {
    final resized = img.copyResize(
      image,
      width: 640,
      height: 640,
      interpolation: img.Interpolation.linear,
    );

    final inputBuffer = Float32List(1 * 640 * 640 * 3);
    int pixelIndex = 0;

    for (int y = 0; y < 640; y++) {
      for (int x = 0; x < 640; x++) {
        final pixel = resized.getPixel(x, y);
        inputBuffer[pixelIndex++] = pixel.r / 255.0;
        inputBuffer[pixelIndex++] = pixel.g / 255.0;
        inputBuffer[pixelIndex++] = pixel.b / 255.0;
      }
    }

    return inputBuffer;
  }

  Future<List<Ingredient>> detectIngredientsInImage(img.Image image) async {
    if (!_isInitialized) {
      await initialize();
      if (!_isInitialized) return [];
    }

    try {
      final inputData = _preprocessImage(image);
      final inputShape = [1, 640, 640, 3];
      final outputShape = [1, 8400, _labels.length + 5];

      var outputTensor = List.generate(
        1,
        (_) => List.generate(8400, (_) => List.filled(_labels.length + 5, 0.0)),
      );

      _interpreter!.run(inputData.reshape(inputShape), outputTensor);

      final detections = _postProcessOutput(outputTensor);
      final List<Ingredient> detectedIngredients = [];

      for (var detection in detections) {
        final labelIndex = detection['class_id'] as int;
        final className = _labels[labelIndex].toLowerCase();
        final confidence = detection['confidence'] as double;

        print('Détection: $className ($confidence)');

        if (ingredientIds.containsKey(className) && confidence > 0.3) {
          final ingredientId = ingredientIds[className]!;

          if (!detectedIngredients.any((i) => i.id == ingredientId)) {
            detectedIngredients.add(
              Ingredient(
                id: ingredientId,
                name: className,
                confidence: confidence,
              ),
            );
          }
        }
      }

      return detectedIngredients;
    } catch (e) {
      print('Erreur de détection: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _postProcessOutput(dynamic output) {
    final List<Map<String, dynamic>> results = [];
    final outputData = output[0] as List<List<double>>;

    const confidenceThreshold = 0.4;
    const iouThreshold = 0.5;

    for (var row in outputData) {
      double maxScore = 0;
      int classId = 0;

      for (int i = 5; i < row.length; i++) {
        if (row[i] > maxScore) {
          maxScore = row[i];
          classId = i - 5;
        }
      }

      if (maxScore > confidenceThreshold) {
        final centerX = row[0];
        final centerY = row[1];
        final width = row[2];
        final height = row[3];

        final left = centerX - width / 2;
        final top = centerY - height / 2;
        final right = centerX + width / 2;
        final bottom = centerY + height / 2;

        results.add({
          'class_id': classId,
          'confidence': maxScore,
          'bbox': [left, top, right, bottom],
        });
      }
    }

    return _applyNMS(results, iouThreshold);
  }

  List<Map<String, dynamic>> _applyNMS(
    List<Map<String, dynamic>> boxes,
    double threshold,
  ) {
    final selected = <Map<String, dynamic>>[];

    boxes.sort((a, b) => b['confidence'].compareTo(a['confidence']));
    final active = List<bool>.filled(boxes.length, true);

    for (int i = 0; i < boxes.length; i++) {
      if (!active[i]) continue;

      selected.add(boxes[i]);
      final boxA = boxes[i]['bbox'];

      for (int j = i + 1; j < boxes.length; j++) {
        if (!active[j]) continue;

        final boxB = boxes[j]['bbox'];
        if (_calculateIoU(boxA, boxB) > threshold) {
          active[j] = false;
        }
      }
    }

    return selected;
  }

  double _calculateIoU(List<double> a, List<double> b) {
    final x1 = math.max(a[0], b[0]);
    final y1 = math.max(a[1], b[1]);
    final x2 = math.min(a[2], b[2]);
    final y2 = math.min(a[3], b[3]);

    final intersection = math.max(0, x2 - x1) * math.max(0, y2 - y1);
    final areaA = (a[2] - a[0]) * (a[3] - a[1]);
    final areaB = (b[2] - b[0]) * (b[3] - b[1]);

    return intersection / (areaA + areaB - intersection);
  }
}

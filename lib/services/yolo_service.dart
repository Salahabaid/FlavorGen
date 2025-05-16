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
    "beef": 23572,
    "bread": 18064,
    "butter": 1001,
    "chicken_breast": 5062,
    "corn": 11168,
    "flour": 20081,
    "ham": 10151,
    "milk": 1077,
    "shrimp": 15152,
    "spinach": 10011457,
    "strawberries": 9316,
    "apple": 9003,
    "banana": 9040,
    "beetroot": 11080,
    "bell_pepper": 11821,
    "broccoli": 11090,
    "carrot": 11124,
    "cheese": 1041009,
    "chicken": 5006,
    "cucumber": 11205,
    "egg": 1123,
    "garlic": 11215,
    "lemon": 9150,
    "mushroom": 11260,
    "onion": 11282,
    "orange": 9200,
    "potato": 11352,
    "rice": 20444,
    "sugar": 19335,
    "thon": 10015121,
    "tomato": 11529,
  };

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final labelsData = await rootBundle.loadString(
        'assets/models/labels.txt',
      );
      _labels =
          labelsData.split('\n').map((e) => e.trim().toLowerCase()).toList();
      print('Labels chargés: $_labels');

      final options =
          InterpreterOptions()
            ..threads = 4
            ..useNnApiForAndroid = true;

      _interpreter = await Interpreter.fromAsset(
        'assets/models/best_float16.tflite', // <-- Mets ici le nom de ton modèle
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
      if (!_isInitialized) {
        print("YoloService not initialized, returning empty list.");
        return [];
      }
    }

    try {
      final inputData = _preprocessImage(image);
      final inputShape = [1, 640, 640, 3];
      
      var outputTensor = List.generate(
        1,
        (_) => List.generate(35, (_) => List.filled(8400, 0.0)),
      );

      print("Running interpreter...");
      _interpreter!.run(inputData.reshape(inputShape), outputTensor);
      print("Interpreter run complete. Output tensor shape: [${outputTensor.length}, ${outputTensor[0].length}, ${outputTensor[0][0].length}]");

      final List<Map<String, dynamic>> detections = _postProcessOutput(outputTensor);
      final List<Ingredient> detectedIngredients = [];

      print("Post-processing returned ${detections.length} detections.");

      for (var detection in detections) {
        final labelIndex = detection['class_id'] as int;
        if (labelIndex < 0 || labelIndex >= _labels.length) {
          print("Warning: Invalid labelIndex $labelIndex detected. Max is ${_labels.length -1}. Skipping.");
          continue;
        }
        final className = _labels[labelIndex];
        final confidence = detection['confidence'] as double;

        print('Processing detection: $className ($confidence)');
        
        if (ingredientIds.containsKey(className)) {
          final ingredientId = ingredientIds[className]!;

          if (!detectedIngredients.any((i) => i.id == ingredientId)) {
            detectedIngredients.add(
              Ingredient(
                id: ingredientId,
                name: className,
                confidence: confidence,
                bbox: detection['bbox'] as List<double>,
              ),
            );
          }
        } else {
          print("Ingredient '$className' not found in ingredientIds map or confidence too low.");
        }
      }

      print('Final detected ingredients in list: ${detectedIngredients.map((i) => i.name).toList()}');
      return detectedIngredients;
    } catch (e, s) {
      print('Erreur de détection in detectIngredientsInImage: $e');
      print('Stack trace: $s');
      return [];
    }
  }

  List<Map<String, dynamic>> _postProcessOutput(List<List<List<double>>> outputTensor) {
    final List<Map<String, dynamic>> results = [];
    
    final List<List<double>> outputData = outputTensor[0];

    final int numDetections = outputData[0].length;
    final int numClasses = _labels.length;

    if (outputData.length != numClasses + 4) {
      print("Warning: Output tensor attributes length (${outputData.length}) does not match numClasses ($numClasses) + 4.");
    }

    const double confidenceThreshold = 0.3;
    const double iouThreshold = 0.5;

    List<Map<String, dynamic>> allBoxes = [];

    for (int i = 0; i < numDetections; i++) {
      double maxClassScore = 0.0;
      int bestClassId = -1;
      String potentialLabel = "";

      // Temporarily log the highest score found for this detection box i
      double currentBoxMaxScore = 0.0; 

      for (int classIdx = 0; classIdx < numClasses; classIdx++) {
        final double score = outputData[4 + classIdx][i];
        if (score > currentBoxMaxScore) { // Keep track of highest score in this box
            currentBoxMaxScore = score;
        }
        if (score > maxClassScore) {
          maxClassScore = score;
          bestClassId = classIdx;
          potentialLabel = _labels[classIdx]; // For logging
        }
      }
      
      // Log this for a few detections to see what scores look like
      if (i < 10) { // Log for first 10 detection proposals
          print("Detection proposal $i: Max score found = $currentBoxMaxScore (Best class if > thresh: $potentialLabel, ID: $bestClassId)");
      }

      if (maxClassScore > confidenceThreshold && bestClassId != -1) {
        final double centerX = outputData[0][i] * 640;
        final double centerY = outputData[1][i] * 640;
        final double width = outputData[2][i] * 640;
        final double height = outputData[3][i] * 640;

        final double left = centerX - (width / 2);
        final double top = centerY - (height / 2);
        final double right = centerX + (width / 2);
        final double bottom = centerY + (height / 2);

        allBoxes.add({
          'class_id': bestClassId,
          'confidence': maxClassScore,
          'bbox': [left, top, right, bottom],
        });
      }
    }
    
    print("Boxes before NMS: ${allBoxes.length}");
    final nmsResults = _applyNMS(allBoxes, iouThreshold);
    print("Boxes after NMS: ${nmsResults.length}");
    return nmsResults;
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

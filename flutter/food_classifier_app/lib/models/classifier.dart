import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';
import 'package:food_classifier_app/utils/image_utils.dart';

class ClassificationResult {
  final String label;
  final Map<String, double> confidenceScores;

  ClassificationResult({required this.label, required this.confidenceScores});
}

class FoodClassifier {
  Interpreter? _interpreter;
  List<String>? _labels;
  static const int INPUT_SIZE = 224; // Standard input size for most food classification models

  Future<void> loadModel() async {
    try {
      // Load TFLite model
      _interpreter = await Interpreter.fromAsset('assets/models/food_model.tflite');
      
      // Load labels
      final labelsData = await File('assets/models/labels.txt').readAsString();
      _labels = labelsData.split('\n');
      
      print('Model and labels loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
      // For development, create a placeholder model if the real one isn't available
      _createPlaceholderLabelsForDevelopment();
    }
  }

  // Only used during development when no model/labels are available
  void _createPlaceholderLabelsForDevelopment() async {
    _labels = ['apple', 'banana', 'burger', 'pizza', 'salad', 'sushi'];
    
    // Write placeholder labels file for development
    try {
      Directory appDir = await getApplicationDocumentsDirectory();
      String labelsPath = '${appDir.path}/labels.txt';
      File labelsFile = File(labelsPath);
      await labelsFile.writeAsString(_labels!.join('\n'));
    } catch (e) {
      print('Error creating placeholder labels: $e');
    }
  }

  Future<ClassificationResult> classifyImage(String imagePath) async {
    if (_interpreter == null) {
      return ClassificationResult(
        label: "Model not loaded", 
        confidenceScores: {'Error': 1.0}
      );
    }
    
    // For development: if no real model is available, return mock data
    if (_interpreter == null && _labels != null) {
      return _getMockPrediction();
    }
    
    try {
      XFile xFile = XFile(imagePath);
      final processedImage = await ImageUtils.processCameraImage(xFile, INPUT_SIZE);
      
      if (processedImage == null) {
        return ClassificationResult(
          label: "Failed to process image", 
          confidenceScores: {'Error': 1.0}
        );
      }
      
      // Convert to input tensor using our utility
      var inputData = ImageUtils.imageToInput(processedImage, INPUT_SIZE);
      
      // Reshape input data to match the model's input shape
      var input = [inputData];
      
      // Output buffer
      var outputShape = _interpreter!.getOutputTensor(0).shape;
      var outputBuffer = List<double>.filled(outputShape.reduce((a, b) => a * b), 0);
      
      // Run inference
      _interpreter!.run(input, {'Softmax': outputBuffer});
      
      // Process results
      Map<String, double> labelConfidences = {};
      int maxIndex = 0;
      
      for (int i = 0; i < outputBuffer.length; i++) {
        if (i < _labels!.length) {
          labelConfidences[_labels![i]] = outputBuffer[i];
          if (outputBuffer[i] > outputBuffer[maxIndex]) {
            maxIndex = i;
          }
        }
      }
      
      String topLabel = maxIndex < _labels!.length ? _labels![maxIndex] : "Unknown";
      
      return ClassificationResult(
        label: topLabel,
        confidenceScores: labelConfidences,
      );
    } catch (e) {
      print('Error during classification: $e');
      return ClassificationResult(
        label: "Classification error", 
        confidenceScores: {'Error': 1.0}
      );
    }
  }
  
  // For development: returns mock prediction data
  ClassificationResult _getMockPrediction() {
    // Generate random confidence scores that sum to 1.0
    final Map<String, double> mockScores = {};
    double totalConfidence = 0.0;
    
    if (_labels != null) {
      for (String label in _labels!) {
        // Random score between 0.0 and 0.5
        double score = (DateTime.now().millisecondsSinceEpoch % 100) / 200.0;
        mockScores[label] = score;
        totalConfidence += score;
      }
      
      // Normalize scores to sum to 1.0
      mockScores.forEach((key, value) {
        mockScores[key] = value / totalConfidence;
      });
      
      // Find the label with highest confidence
      String topLabel = mockScores.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      
      return ClassificationResult(
        label: topLabel,
        confidenceScores: mockScores,
      );
    } else {
      return ClassificationResult(
        label: "No labels available",
        confidenceScores: {'Error': 1.0},
      );
    }
  }

  void close() {
    _interpreter?.close();
  }
}
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

class ImageUtils {
  /// Processes a camera image for model input
  /// Converts to the required format and size for the TFLite model
  static Future<img.Image?> processCameraImage(XFile imageFile, int inputSize) async {
    try {
      final File file = File(imageFile.path);
      final Uint8List bytes = await file.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);
      
      if (image == null) return null;
      
      // Resize the image to the required input size for the model
      final img.Image resizedImage = img.copyResize(
        image,
        width: inputSize,
        height: inputSize,
      );
      
      return resizedImage;
    } catch (e) {
      print('Error processing camera image: $e');
      return null;
    }
  }

  /// Converts the image to a list of normalized pixel values
  /// Format: [r, g, b] with values normalized to [0, 1]
  static List<List<List<double>>> imageToInput(img.Image image, int inputSize) {
    return List.generate(
      inputSize,
      (y) => List.generate(
        inputSize,
        (x) {
          final pixel = image.getPixel(x, y);
          // Normalize pixel values to [0, 1]
          return [
            pixel.r / 255.0,
            pixel.g / 255.0,
            pixel.b / 255.0,
          ];
        },
      ),
    );
  }
  
  /// Saves a temporary image file from camera data
  /// Useful for debugging or visualization
  static Future<String> saveTemporaryImage(XFile imageFile, String prefix) async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${directory.path}/${prefix}_$timestamp.jpg';
    
    final File file = File(imageFile.path);
    await file.copy(path);
    
    return path;
  }
}
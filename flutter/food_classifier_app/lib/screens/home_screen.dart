import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/database_helper.dart';
import '../services/auth_service.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart'; // Import the image_picker package

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  CameraController? controller;
  List<CameraDescription>? cameras;
  int selectedCameraIndex = 0;
  XFile? imageFile;
  bool _isProcessing = false;
  Map<String, dynamic>? _predictionResult;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AuthService _authService = AuthService();
  int? _currentUserId;
  bool _isGalleryMode = false; // Track if we're in gallery mode

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if we should be in gallery mode
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args == 'open_gallery') {
      // Set gallery mode flag
      _isGalleryMode = true;

      // Open gallery picker after a short delay to ensure everything is initialized
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted && _isGalleryMode && !_isProcessing) {
          _pickImageFromGallery();
        }
      });
    } else {
      // If not gallery mode, initialize camera
      _initializeCamera();
    }
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _currentUserId = user.id;
      });
    }
  }

  Future<void> _initializeCamera() async {
    // Skip camera initialization if in gallery mode
    if (_isGalleryMode) return;

    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      controller = CameraController(
        cameras![selectedCameraIndex],
        ResolutionPreset.high,
      );
      await controller!.initialize();
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Skip camera handling if in gallery mode
    if (_isGalleryMode) return;

    final CameraController? cameraController = controller;

    // App state changed before controller was initialized
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show different initial states based on mode
    if (_isGalleryMode) {
      // For gallery mode, show a simple loading indicator or placeholder when no image selected
      if (_predictionResult == null && imageFile == null) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gallery Upload'),
            backgroundColor: Colors.lightBlue,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.photo_library),
                tooltip: 'Pick another image',
                onPressed: !_isProcessing ? _pickImageFromGallery : null,
              ),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 16),
                Text(
                  _isProcessing
                      ? 'Processing image...'
                      : 'Select an image to classify',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                ),
                if (_isProcessing) ...[
                  SizedBox(height: 20),
                  CircularProgressIndicator(),
                ],
              ],
            ),
          ),
          floatingActionButton: !_isProcessing
              ? FloatingActionButton(
                  onPressed: _pickImageFromGallery,
                  backgroundColor: Colors.lightBlue,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.add_photo_alternate),
                )
              : null,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      }
    } else {
      // Normal camera mode
      if (controller == null || !controller!.value.isInitialized) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
    }

    // The main UI is the same for both modes once we have an image or result
    return Scaffold(
      appBar: AppBar(
        title: Text(_isGalleryMode ? 'Gallery Upload' : 'Classify Food'),
        backgroundColor: _isGalleryMode ? Colors.lightBlue : Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
                _isGalleryMode ? Icons.photo_library : Icons.photo_library),
            tooltip: 'Pick from gallery',
            onPressed: _isProcessing ? null : _pickImageFromGallery,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _predictionResult != null
                ? _buildResultView()
                : _isGalleryMode
                    ? (imageFile != null
                        ? _buildGalleryPreview()
                        : const SizedBox.shrink())
                    : _buildCameraPreview(),
          ),
        ],
      ),
      floatingActionButton: _predictionResult == null
          ? (_isGalleryMode
              ? (imageFile != null && !_isProcessing
                  ? FloatingActionButton(
                      onPressed: () => _processImage(imageFile!.path),
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                      child: _isProcessing
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Icon(Icons.check),
                    )
                  : null)
              : FloatingActionButton(
                  onPressed: _isProcessing ? null : _takePicture,
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  child: _isProcessing
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Icon(Icons.camera_alt),
                ))
          : FloatingActionButton.extended(
              onPressed: () async {
                // Show loading indicator
                setState(() {
                  _isProcessing = true;
                });
                
                // Save the prediction to database
                await _savePredictionToDatabase(_predictionResult!);
                
                // Show success message
                if (mounted) {
                  setState(() {
                    _isProcessing = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Added to history successfully!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2.0,
                      ),
                    )
                  : const Icon(Icons.add),
              label: const Text('ADD TO HISTORY'),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Add a gallery preview widget
  Widget _buildGalleryPreview() {
    if (imageFile == null) return const SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(imageFile!.path),
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
          ),
        ),
        if (_isProcessing)
          Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Processing image...')
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: AspectRatio(
        aspectRatio: 1 / controller!.value.aspectRatio,
        child: CameraPreview(controller!),
      ),
    );
  }

  // Reset based on the current mode
  void _resetScreen() {
    setState(() {
      imageFile = null;
      _predictionResult = null;
    });
  }

  // The rest of your methods remain the same...

  // Helper method to capitalize the first letter of a string
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Added method to properly format images before upload
  Future<File> _processImageForUpload(String imagePath) async {
    // Read bytes from the original image
    final bytes = await File(imagePath).readAsBytes();

    // Decode the image
    final img.Image? decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) {
      throw Exception('Failed to decode image');
    }

    // Create JPEG image with proper encoding
    final jpegBytes = img.encodeJpg(decodedImage, quality: 90);

    // Save to temporary directory with proper extension
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
      '${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    // Write the JPEG data to the file
    await tempFile.writeAsBytes(jpegBytes);
    print('📊 DEBUG: Processed image saved to: ${tempFile.path}');
    print('📊 DEBUG: Processed image size: ${await tempFile.length()} bytes');

    return tempFile;
  }

  Future<void> _processImage(String imagePath) async {
    // Check for user ID first
    if (_currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to make predictions')),
        );
        // Navigate to login screen
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    try {
      // Process image before uploading (using our new method)
      File processedImageFile = await _processImageForUpload(imagePath);
      print('📊 DEBUG: Using processed image: ${processedImageFile.path}');
      print(
          '📊 DEBUG: Processed image size: ${await processedImageFile.length()} bytes');

      // Create multipart request using the serverUrl from DatabaseHelper
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_dbHelper.serverUrl}/predict'),
      );

      // Add file to request
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          processedImageFile.path,
        ),
      );

      // Add user_id to request
      request.fields['user_id'] = _currentUserId.toString();

      print(
          '📤 DEBUG: Sending image to server: ${_dbHelper.serverUrl}/predict');
      print('📤 DEBUG: With user_id: ${_currentUserId.toString()}');

      // Send request
      var streamedResponse = await request.send();
      print('📥 DEBUG: Response status code: ${streamedResponse.statusCode}');

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('📥 DEBUG: Server response: ${response.body}');

        // Check if ingredients were detected
        List<dynamic> ingredients = result['ingredients'] ?? [];
        if (ingredients.isNotEmpty) {
          print('🍲 DEBUG: Detected ${ingredients.length} ingredients:');
          for (var ingredient in ingredients) {
            print(
                '🍲 DEBUG: ${ingredient['name']}: ${ingredient['confidence']}%');
          }
        } else {
          print('🍲 DEBUG: No ingredients detected');
        }

        if (mounted) {
          setState(() {
            _predictionResult = result;
            _isProcessing = false;
          });
        }

        // Don't automatically save to database
        // await _savePredictionToDatabase(result);
      } else {
        print('Error: ${response.statusCode}');
        print('Error body: ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Error: ${response.statusCode} - ${response.body}')),
          );
        }
      }
    } catch (e) {
      print('Error processing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: $e')),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    if (!controller!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile file = await controller!.takePicture();
      setState(() {
        imageFile = file;
      });

      await _processImage(file.path);
    } catch (e) {
      print('Error taking picture: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _savePredictionToDatabase(Map<String, dynamic> result) async {
    try {
      // Get category info from the prediction result directly
      final categoryName = result['class_name'] as String;
      final confidence = result['confidence'] as num;

      // Save image file to app directory if needed
      String? savedImagePath;
      if (imageFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final filename =
            'food_classification_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = File('${appDir.path}/$filename');
        await File(imageFile!.path).copy(savedImage.path);
        savedImagePath = savedImage.path;
      }

      // Instead of calling getFoodCategoryByName which uses a direct DB connection,
      // we'll fetch the food category ID using the API
      try {
        // Make a GET request to get food category by name
        final categoryResponse = await http.get(
          Uri.parse('${_dbHelper.serverUrl}/api/food-categories'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 5));

        if (categoryResponse.statusCode != 200) {
          throw Exception('Failed to fetch food categories');
        }

        final categories = jsonDecode(categoryResponse.body) as List;
        final category = categories.firstWhere(
          (cat) =>
              (cat['name'] as String).toLowerCase() ==
              categoryName.toLowerCase(),
          orElse: () =>
              throw Exception('Food category not found: $categoryName'),
        );

        final categoryId = category['id'] as int;

        // Now use the API to save the prediction with the obtained category ID
        print(
            '📤 Saving prediction via API: ${_dbHelper.serverUrl}/api/predictions');

        // Prepare the prediction data
        final predictionData = {
          'user_id': _currentUserId,
          'food_id': categoryId,
          'confidence': confidence.toDouble(),
          'image_path': savedImagePath,
        };

        print('📤 Prediction data: $predictionData');

        // Try up to 3 times with increasing delays
        for (int attempt = 1; attempt <= 3; attempt++) {
          try {
            // Use the /api/predictions endpoint for saving prediction data
            final response = await http
                .post(
                  Uri.parse('${_dbHelper.serverUrl}/api/predictions'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(predictionData),
                )
                .timeout(const Duration(seconds: 10));

            if (response.statusCode == 200 || response.statusCode == 201) {
              final responseData = jsonDecode(response.body);
              print(
                  '✅ Prediction saved via API: ${responseData['message']} (ID: ${responseData['id']})');
              return;
            } else {
              print(
                  '⚠️ Error saving prediction (attempt $attempt): ${response.statusCode} - ${response.body}');
              if (attempt == 3) {
                throw Exception(
                    'Server returned status code ${response.statusCode}');
              }
            }
          } catch (e) {
            print('⚠️ API request failed (attempt $attempt): $e');
            if (attempt == 3) throw e;
            await Future.delayed(Duration(seconds: attempt * 2));
          }
        }
      } catch (e) {
        print('❌ Error with API: $e');
        throw e;
      }
    } catch (e) {
      print('❌ Error saving prediction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save prediction. Please try again later.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Method to pick image from gallery
  Future<void> _pickImageFromGallery() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _predictionResult = null; // Clear previous results
    });

    try {
      final ImagePicker picker = ImagePicker();
      // Pick an image from the gallery
      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Reduce quality slightly to decrease file size
      );

      if (pickedImage == null) {
        // User cancelled the picker
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      print('📊 DEBUG: Image picked from gallery: ${pickedImage.path}');

      setState(() {
        imageFile = pickedImage;
      });

      // In gallery mode, let user confirm before processing
      if (_isGalleryMode) {
        setState(() {
          _isProcessing = false; // Allow user to review image before processing
        });
      } else {
        // Auto-process in normal mode
        await _processImage(pickedImage.path);
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Widget _buildResultView() {
    final prediction = _predictionResult!;
    final className = prediction['class_name'] as String;
    final confidencePercent = prediction['confidence'].toStringAsFixed(1);
    
    // Get nutritional information if available
    final calories = prediction['calories'] is num ? prediction['calories'] as num : null;

    // Get ingredients/side dishes from the prediction result
    final List<dynamic> ingredients = prediction['ingredients'] ?? [];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Classification Result',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(imageFile!.path),
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Icon(
                            Icons.restaurant,
                            size: 28,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                className.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Confidence: $confidencePercent%',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              if (calories != null)
                                Text(
                                  'Calories: ${calories.toStringAsFixed(0)} kcal',
                                  style: TextStyle(
                                    color: Colors.orange.shade800,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Show ingredients section if available
                    if (ingredients.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Detected Ingredients:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ingredients.map<Widget>((ingredient) {
                          final name = ingredient['name'] as String;
                          final confidence = ingredient['confidence'] as num;
                          final double confidenceValue = confidence.toDouble();

                          // Choose color based on confidence
                          Color chipColor;
                          if (confidenceValue >= 90) {
                            chipColor = Colors.green;
                          } else if (confidenceValue >= 70) {
                            chipColor = Colors.orange;
                          } else {
                            chipColor = Colors.red;
                          }

                          return Chip(
                            avatar: Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 16,
                            ),
                            label: Text(
                              '${_capitalizeFirstLetter(name)} (${confidenceValue.toStringAsFixed(1)}%)',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: chipColor,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Replace the Row with a more responsive layout
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/food_info',
                      arguments: className,
                    );
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Food Info'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _resetScreen,
                  icon: const Icon(Icons.refresh),
                  label: const Text('New Scan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

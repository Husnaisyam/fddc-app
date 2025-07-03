<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Food Classifier App - Flutter Project

This is a Flutter application that uses TensorFlow Lite to classify food items from a live camera feed. The project is structured to make it easy to integrate a custom food classification model.

## Key Components

- **camera**: Used for live camera feed access
- **tflite_flutter**: Integration with TensorFlow Lite models
- **permission_handler**: Manages camera and storage permissions
- **image**: For image processing and transformation

## Development Context

- The app is designed to work in a development mode without a real model
- The app should ultimately integrate with a pre-trained food classification model
- When suggesting code modifications, consider both iOS and Android platforms
- Ensure proper permission handling for camera access
- Focus on efficient image processing for real-time classification

## Project Structure Hints

- `lib/screens/home_screen.dart` - Contains the main UI with camera preview and prediction results
- `lib/models/classifier.dart` - TensorFlow Lite integration and classification logic
- `lib/utils/image_utils.dart` - Helper methods for image processing
- `assets/models/` - Location for TFLite model and labels.txt files

## Common Tasks

- Optimizing the camera preview
- Integrating TensorFlow Lite models
- Processing images for model input
- Displaying prediction results
- Handling app lifecycle with camera resources
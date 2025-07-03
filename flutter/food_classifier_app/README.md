# Food Classifier App

A Flutter application that uses your trained food classification model to predict food types from a live camera feed.

## Features

- Real-time food classification using the device camera
- Display of confidence scores for multiple food categories
- Support for both iOS and Android platforms
- Optimized camera integration with permission handling

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio or Xcode for platform-specific development
- A TensorFlow Lite food classification model

### Installing

1. Clone this repository
2. Run `flutter pub get` to install dependencies
3. Place your TensorFlow Lite model in the `assets/models/` directory:
   - The main model file should be named `food_model.tflite`
   - The labels file should be named `labels.txt` (one label per line)

### Running the app

```bash
flutter run
```

## Model Integration

### Using Your Own Food Classification Model

This app is designed to work with your custom food classification model. To integrate your model:

1. Convert your Keras/TensorFlow model to TFLite format:

```python
import tensorflow as tf

# Load your existing model
model = tf.keras.models.load_model("path/to/your/model.h5")

# Convert to TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# Save the model
with open('food_model.tflite', 'wb') as f:
    f.write(tflite_model)
```

2. Export your class labels to a text file (one label per line)
3. Place both files in the `assets/models/` directory
4. Update the `INPUT_SIZE` constant in `lib/models/classifier.dart` if your model requires a different input size than 224x224

### Development Mode

If you run the app without a real model, it will operate in development mode with simulated predictions for the following food categories:
- apple
- banana
- burger
- pizza
- salad
- sushi

## Project Structure

- `lib/`
  - `main.dart` - App entry point and configuration
  - `screens/`
    - `home_screen.dart` - Main UI with camera and prediction display
  - `models/`
    - `classifier.dart` - Food classification implementation using TFLite

## Customization

- Adjust the UI layout in `home_screen.dart`
- Modify prediction frequency in the `_predictionTimer` configuration
- Change the model processing parameters in `classifier.dart`

## Troubleshooting

- If camera preview doesn't appear, check that permissions are properly granted
- If classification results are incorrect, verify that the model and labels are properly formatted
- For iOS deployment issues, ensure the Info.plist contains all required permission descriptions

## License

This project is licensed under the MIT License

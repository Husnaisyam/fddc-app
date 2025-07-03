import tensorflow as tf
import os

# Ensure TF warnings are minimal
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

def convert_to_tflite():
    # Load the Keras model
    model = tf.keras.models.load_model("food_classification_model.keras")
    
    # Convert to TFLite
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()
    
    # Save the TFLite model
    output_path = "flutter/food_classifier_app/assets/models/food_model.tflite"
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    print(f"Model converted and saved to {output_path}")

if __name__ == "__main__":
    convert_to_tflite()
import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

import tensorflow as tf
import numpy as np
from tensorflow.keras.preprocessing import image

# Load the trained model
model = tf.keras.models.load_model("nasi_lemak_side_dishes_model.keras")

# Define side dish label
class_label = "Ikan Bilis"  # Currently only detecting one class

def predict_side_dish(img_path):
    # Load and preprocess the image
    img = image.load_img(img_path, target_size=(224, 224))
    img_array = image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0)
    img_array = img_array / 255.0

    # Make prediction
    prediction = model.predict(img_array)
    
    # Get confidence score (probability of the class being present)
    confidence = float(prediction[0][0] * 100)
    
    # Determine if the side dish is present (using 0.5 threshold)
    is_present = prediction[0][0] > 0.5
    
    if is_present:
        print(f"\n✅ Detected {class_label} with {confidence:.2f}% confidence")
    else:
        print(f"\n❌ {class_label} not detected (confidence: {confidence:.2f}%)")
    
    return {
        'name': class_label,
        'confidence': confidence,
        'is_present': is_present
    }

if __name__ == "__main__":
    # Test with a sample image
    test_image_path = "test_image/nasi_lemak_side.jpeg"  # Update with your test image
    if os.path.exists(test_image_path):
        result = predict_side_dish(test_image_path)
    else:
        print(f"Please place a test image at {test_image_path}")
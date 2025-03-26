import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

import tensorflow as tf
import numpy as np
from tensorflow.keras.preprocessing import image

# Load the trained model
model = tf.keras.models.load_model("food_classification_model.keras")

# Define food labels (update this with your dataset classes)
class_labels = ["Cendol", "Ketupat", "Laksa", "Nasi Lemak"]  # Change this to match your dataset

# Load an image from your local directory
img_path = "test_image/laksa.jpeg"  # Ensure this path is correct
img = image.load_img(img_path, target_size=(224, 224))  # Resize to match model input size

# Convert image to array
img_array = image.img_to_array(img)
img_array = np.expand_dims(img_array, axis=0)  # Add batch dimension
img_array = img_array / 255.0  # Normalize pixel values


# Predict the class
predictions = model.predict(img_array)
predicted_class = np.argmax(predictions)  # Get the highest probability class
food_name = class_labels[predicted_class]  # Convert index to label
confidence = np.max(predictions) * 100  # Get confidence score

# Print the results
print(f"Predicted food: {food_name} with {confidence:.2f}% confidence")

predictions = model.predict(img_array)

# Print all class probabilities
for i, class_name in enumerate(class_labels):
    print(f"{class_name}: {predictions[0][i] * 100:.2f}%")

# Show the final prediction
predicted_class = np.argmax(predictions)
food_name = class_labels[predicted_class]
confidence = np.max(predictions) * 100

print(f"\n🍽️ Predicted Food: {food_name} with {confidence:.2f}% confidence")


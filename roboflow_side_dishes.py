from roboflow import Roboflow
import cv2
import numpy as np
from PIL import Image
import os

# Initialize Roboflow with Malaysian Food Recognition 2 model
try:
    rf = Roboflow(api_key="AePngQLn5w9bvJ0Yve4J")
    workspace = rf.workspace("malaysian-dishes-classification")
    project = workspace.project("malaysian-food-recognition-2")
    model = project.version(1).model
    print("✅ Roboflow model initialized successfully")
    
    # Update labels to match Malaysian Food Recognition 2 model classes
    FOOD_LABELS = [
        "Anchovies", "Boiled-Egg", "Chicken Rendang", "Cucumber",
        "Fried-Chicken", "Fried-Egg", "Peanuts", "Rice", "Sambal"
    ]
    
except Exception as e:
    print(f"⚠️ Roboflow initialization error: {str(e)}")
    model = None
    FOOD_LABELS = []

def detect_side_dishes(image_path):
    """
    Detect side dishes in an image using Roboflow model
    """
    try:
        if model is None:
            print("⚠️ Roboflow model not initialized")
            return []
            
        # Predict on the image
        prediction = model.predict(image_path, confidence=40, overlap=30)
        
        # Process predictions
        detections = []
        for pred in prediction:
            confidence = pred['confidence']
            class_name = pred['class']
            
            detections.append({
                'name': class_name,
                'confidence': round(confidence * 100, 2)
            })
        
        # Sort by confidence
        return sorted(detections, key=lambda x: x['confidence'], reverse=True)
        
    except Exception as e:
        print(f"Error in detection: {str(e)}")
        return []

if __name__ == "__main__":
    # Test the detection
    test_image = "test_image/nasi_lemak.jpeg"
    if os.path.exists(test_image):
        results = detect_side_dishes(test_image)
        print("\n🍽️ Detected Side Dishes:")
        for detection in results:
            print(f"{detection['name']}: {detection['confidence']}%")
    else:
        print(f"Test image not found: {test_image}")
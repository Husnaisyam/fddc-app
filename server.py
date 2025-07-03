from flask import Flask, request, jsonify, send_from_directory
import tensorflow as tf
import numpy as np
from tensorflow.keras.preprocessing import image
from PIL import Image
import io
import base64
import mysql.connector
import hashlib
import os
from flask_cors import CORS
import time
from datetime import datetime
import json

app = Flask(__name__)
CORS(app)

# Configure TensorFlow to be less verbose
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

print("🔄 Loading TensorFlow models...")

# Load both models
try:
    main_model = tf.keras.models.load_model("food_classification_model.keras")
    side_dishes_model = tf.keras.models.load_model("nasi_lemak_side_dishes_model.keras")
    print("✅ Models loaded successfully")
except Exception as e:
    print(f"❌ Error loading models: {e}")

# Define food labels
main_labels = ["Cendol", "Ketupat", "Laksa", "Nasi Ayam", "Nasi Lemak"]
side_dish_labels = ["Ikan Bilis", "Telur", "Sambal", "Timun", "Kacang"]

def get_db_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="",
        database="food_classifier_db"
    )

def detect_side_dishes_roboflow(image_path):
    """
    Detect side dishes using Roboflow API with Python requests
    Cross-platform implementation that works on Windows and Unix
    """
    try:
        print(f"📸 Detecting side dishes in {image_path} using Roboflow API (cross-platform method)...")
        
        # Check if file exists
        if not os.path.exists(image_path):
            print(f"❌ ERROR: Image file does not exist: {image_path}")
            return []
        
        # Import required libraries
        try:
            import requests
            import base64
            import json
        except ImportError as e:
            print(f"❌ ERROR: Required library not found: {e}")
            print("Please install required libraries: pip install requests")
            return []
        
        # API configuration
        api_key = "AePngQLn5w9bvJ0Yve4J"
        model_id = "ingredient-2kc8g"
        version = "2"
        
        # Build the API URL
        api_url = f"https://detect.roboflow.com/{model_id}/{version}?api_key={api_key}"
        print(f"🔄 Preparing API request to model '{model_id}/{version}'")
        
        # Read and encode image file
        with open(image_path, "rb") as image_file:
            image_data = image_file.read()
            image_base64 = base64.b64encode(image_data).decode("utf-8")
        
        # Make the API request
        print("🔄 Sending request to Roboflow API...")
        response = requests.post(
            api_url,
            data=image_base64,
            headers={"Content-Type": "application/x-www-form-urlencoded"}
        )
        
        # Check if request was successful
        if response.status_code != 200:
            print(f"❌ API request failed with status code: {response.status_code}")
            print(f"❌ Response: {response.text}")
            return []
        
        # Parse the JSON result
        try:
            response_json = response.json()
            print(f"✅ Raw Roboflow API response: {response_json}")
            
            # Check for error responses
            if isinstance(response_json, dict) and 'message' in response_json:
                if response_json['message'] == 'Forbidden':
                    print("❌ API Error: Forbidden - Check your API key and model permissions")
                    return []
                    
            # Extract predictions
            detections = []
            if "predictions" in response_json:
                for pred in response_json["predictions"]:
                    class_name = pred.get("class", "Unknown")
                    confidence = pred.get("confidence", 0)
                    
                    detections.append({
                        'name': class_name,
                        'confidence': round(confidence * 100, 2)  # Convert to percentage
                    })
                    print(f"📌 Detected {class_name} with confidence {confidence * 100:.2f}%")
                
                # Sort by confidence
                detections = sorted(detections, key=lambda x: x['confidence'], reverse=True)
            else:
                print("🔍 No side dish predictions found in result")
            
            print(f"✅ Side dish detections: {detections}")
            return detections
                
        except json.JSONDecodeError as e:
            print(f"❌ Failed to parse JSON response: {e}")
            print(f"Response: {response.text}")
            return []
            
    except Exception as e:
        print(f"❌ Roboflow detection error: {str(e)}")
        print(f"❌ Error type: {type(e)}")
        import traceback
        print(f"❌ Traceback: {traceback.format_exc()}")
        return []

def detect_side_dishes_local(img_array):
    """
    Detect side dishes using local TensorFlow model
    Returns prediction for Ikan Bilis (currently only one class)
    """
    prediction = side_dishes_model.predict(img_array)
    confidence = float(prediction[0][0])  # Already between 0 and 1
    
    # Lower threshold for detection from 0.5 to 0.3
    is_present = confidence > 0.3
    
    # Print raw confidence for debugging
    print(f"🍲 Side dish raw confidence: {confidence:.4f} (Threshold: 0.3)")
    
    if is_present:
        print(f"✅ Detected Ikan Bilis with {confidence * 100:.2f}% confidence")
        return [{
            'name': 'Ikan Bilis',
            'confidence': round(confidence * 100, 2)  # Convert to percentage
        }]
    else:
        print(f"❌ No Ikan Bilis detected (confidence: {confidence * 100:.2f}%)")
    return []  # Return empty list if side dish is not detected

@app.route('/api/predictions/history/<int:user_id>', methods=['GET'])
def get_user_predictions(user_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        query = """
        SELECT 
            p.*, 
            f.name as food_name, 
            f.description as food_description,
            fi.calories, fi.protein, fi.carbs, fi.fats,
            GROUP_CONCAT(
                CONCAT(i.name, ':', pi.confidence * 100)
                ORDER BY pi.confidence DESC
                SEPARATOR ','
            ) as ingredients
        FROM food_predictions p
        LEFT JOIN food_categories f ON p.food_category_id = f.id
        LEFT JOIN food_info fi ON p.food_category_id = fi.food_category_id
        LEFT JOIN prediction_ingredients pi ON p.id = pi.prediction_id
        LEFT JOIN ingredients i ON pi.ingredient_id = i.id
        WHERE p.user_id = %s AND i.name IS NOT NULL
        GROUP BY p.id
        ORDER BY p.created_at DESC
        """
        cursor.execute(query, (user_id,))
        predictions = cursor.fetchall()
        
        for pred in predictions:
            pred['created_at'] = pred['created_at'].isoformat()
            pred['confidence'] = float(pred['confidence'])
            if pred['calories']:
                pred['calories'] = float(pred['calories'])
            if pred['protein']:
                pred['protein'] = float(pred['protein'])
            if pred['carbs']:
                pred['carbs'] = float(pred['carbs'])
            if pred['fats']:
                pred['fats'] = float(pred['fats'])
            if pred['ingredients']:
                # Parse the concatenated string into a list of ingredients
                ingredients_list = []
                for item in pred['ingredients'].split(','):
                    name, confidence = item.split(':')
                    ingredients_list.append({
                        'name': name,
                        'confidence': float(confidence)
                    })
                pred['ingredients'] = ingredients_list
            else:
                pred['ingredients'] = []
        
        cursor.close()
        conn.close()
        return jsonify(predictions)
    
    except Exception as e:
        print(f"Error in get_user_predictions: {str(e)}")  # Add debug print
        return jsonify({'error': str(e)}), 500

@app.route('/api/predictions', methods=['POST'])
def save_prediction():
    try:
        data = request.json
        conn = get_db_connection()
        cursor = conn.cursor()
        
        query = """
        INSERT INTO food_predictions
        (user_id, food_category_id, confidence, image_path, created_at)
        VALUES (%s, %s, %s, %s, %s)
        """
        
        cursor.execute(query, (
            data['user_id'],
            data['food_id'],
            data['confidence'],
            data['image_path'],
            datetime.now()
        ))
        
        conn.commit()
        prediction_id = cursor.lastrowid
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'id': prediction_id,
            'message': 'Prediction saved successfully'
        })
        
    except Exception as e:
        # Print detailed error information
        import traceback
        error_traceback = traceback.format_exc()
        print(f"❌ Error in save_prediction: {str(e)}")
        print(f"❌ Request data: {request.data}")
        print(f"❌ Traceback: {error_traceback}")
        return jsonify({'error': str(e)}), 500

@app.route('/predict', methods=['POST'])
def predict_main_dish():
    try:
        # Get user_id from request
        user_id = request.form.get('user_id') if 'file' in request.files else request.json.get('user_id')
        if not user_id:
            return jsonify({'error': 'User ID is required'}), 400

        # Check if request has a file or JSON
        if 'file' in request.files:
            file = request.files['file']
            print(f"📊 DEBUG: Received file: {file.filename}, MIME type: {file.content_type}")
            
            # Create uploads directory if it doesn't exist
            os.makedirs('uploads', exist_ok=True)
            
            # Generate a unique filename with proper extension
            timestamp = int(time.time())
            filename = f'prediction_{user_id}_{timestamp}.jpg'
            image_path = os.path.join('uploads', filename)
            
            # Properly handle the image data
            try:
                # Save the image
                file.save(image_path)
                
                # Verify the saved file
                if os.path.exists(image_path):
                    filesize = os.path.getsize(image_path)
                    print(f"✅ Image saved successfully to {image_path} (Size: {filesize} bytes)")
                    
                    # Attempt to open the image to verify integrity
                    img = Image.open(image_path)
                    img_format = img.format
                    img_size = img.size
                    print(f"✅ Image verified: Format: {img_format}, Size: {img_size[0]}x{img_size[1]}")
                    
                    # Ensure image is in JPEG format
                    if img_format != 'JPEG':
                        print(f"⚠️ Converting image from {img_format} to JPEG format")
                        img = img.convert('RGB')
                        img.save(image_path, 'JPEG', quality=90)
                        print(f"✅ Image converted to JPEG and saved to {image_path}")
                else:
                    print(f"❌ Failed to save image: File does not exist at {image_path}")
                    return jsonify({'error': 'Failed to save uploaded image'}), 500
            except Exception as e:
                print(f"❌ Error saving or processing image: {str(e)}")
                return jsonify({'error': f'Error processing image: {str(e)}'}), 500
                
        elif request.is_json:
            img_data = request.json['image']
            if "," in img_data:  # Handle base64 format with data URI prefix
                img_bytes = base64.b64decode(img_data.split(',')[1])
            else:
                img_bytes = base64.b64decode(img_data)
                
            # Use PIL to verify and process the image
            try:
                img = Image.open(io.BytesIO(img_bytes))
                
                # Create uploads directory and save
                os.makedirs('uploads', exist_ok=True)
                timestamp = int(time.time())
                image_path = f'uploads/prediction_{user_id}_{timestamp}.jpg'
                
                # Convert to RGB if needed and save as JPEG
                img = img.convert('RGB')
                img.save(image_path, format='JPEG', quality=90)
                print(f"✅ Base64 image saved to {image_path}")
            except Exception as e:
                print(f"❌ Error processing base64 image: {str(e)}")
                return jsonify({'error': f'Error processing image: {str(e)}'}), 500
        else:
            return jsonify({'error': 'No image provided'}), 400
        
        # Resize and preprocess the image
        try:
            img = Image.open(image_path)
            img = img.resize((224, 224))
            img_array = image.img_to_array(img)
            img_array = np.expand_dims(img_array, axis=0)
            img_array = img_array / 255.0
        except Exception as e:
            print(f"❌ Error preprocessing image: {str(e)}")
            return jsonify({'error': f'Error preprocessing image: {str(e)}'}), 500
        
        # Make main dish prediction
        predictions = main_model.predict(img_array)
        predicted_class = np.argmax(predictions)
        class_name = main_labels[predicted_class].lower()
        confidence = float(predictions[0][predicted_class])  # Already between 0 and 1
        print(f"🍽️ Main dish prediction: {class_name} with confidence {confidence * 100:.2f}%")

        # Use only Roboflow for side dish detection
        print("🔍 Starting side dish detection with Roboflow...")
        side_dish_predictions = detect_side_dishes_roboflow(image_path)
        print(f"✅ Roboflow side dish predictions: {side_dish_predictions}")
        
        # Save to database
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Get food category id
        cursor.execute("SELECT id FROM food_categories WHERE name = %s", (class_name,))
        category = cursor.fetchone()
        
        if category:
            category_id = category[0]
            # Save main prediction (confidence already between 0 and 1)
            cursor.execute("""
                INSERT INTO food_predictions 
                (user_id, food_category_id, confidence, image_path) 
                VALUES (%s, %s, %s, %s)
            """, (user_id, category_id, confidence, image_path))
            
            prediction_id = cursor.lastrowid
            
            # Save detected side dishes
            for side_dish in side_dish_predictions:
                # Get or create ingredient
                cursor.execute("SELECT id FROM ingredients WHERE name = %s", (side_dish['name'],))
                ingredient = cursor.fetchone()
                if ingredient:
                    cursor.execute("""
                        INSERT INTO prediction_ingredients 
                        (prediction_id, ingredient_id, confidence) 
                        VALUES (%s, %s, %s)
                    """, (prediction_id, ingredient[0], side_dish['confidence'] / 100.0))
            
            conn.commit()
            
            # Get nutritional information for the food
            cursor.execute("""
                SELECT calories, protein, carbs, fats 
                FROM food_info 
                WHERE food_category_id = %s
            """, (category_id,))
            
            nutrition_info = cursor.fetchone()
            
            # Build response with nutritional information if available
            response = {
                'class_name': class_name,
                'confidence': round(confidence * 100, 2),  # Convert to percentage only when returning
                'ingredients': side_dish_predictions
            }
            
            if nutrition_info:
                calories, protein, carbs, fats = nutrition_info
                response.update({
                    'calories': calories,
                    'protein': protein,
                    'carbs': carbs,
                    'fats': fats
                })
            
            return jsonify(response)
        
        return jsonify({'error': 'Food category not found'}), 404
        
    except Exception as e:
        print(f"❌ Error in predict_main_dish: {str(e)}")
        import traceback
        print(f"❌ Traceback: {traceback.format_exc()}")
        return jsonify({'error': str(e)}), 500

@app.route('/predict/side-dishes', methods=['POST'])
def predict_side_dishes():
    try:
        # Get the image from the POST request
        img_data = request.json['image']
        img_bytes = base64.b64decode(img_data.split(',')[1])
        
        # Convert to PIL Image
        img = Image.open(io.BytesIO(img_bytes))
        img = img.resize((224, 224))
        
        # Convert to array and preprocess
        img_array = image.img_to_array(img)
        img_array = np.expand_dims(img_array, axis=0)
        img_array = img_array / 255.0
        
        # Make prediction
        prediction = side_dishes_model.predict(img_array)
        confidence = float(prediction[0][0])
        
        # Lower threshold for detection from 0.5 to 0.3
        is_present = confidence > 0.3
        
        # Print raw confidence for debugging
        print(f"🍲 Side dishes endpoint - Raw confidence: {confidence:.4f} (Threshold: 0.3)")
        
        # Format results
        detected_sides = []
        if is_present:
            print(f"✅ Side dishes endpoint - Detected Ikan Bilis with {confidence * 100:.2f}% confidence")
            detected_sides.append({
                'name': 'Ikan Bilis',
                'confidence': round(confidence * 100, 2)
            })
        else:
            print(f"❌ Side dishes endpoint - No Ikan Bilis detected (confidence: {confidence * 100:.2f}%)")
        
        return jsonify({
            'detected_sides': detected_sides,
            'all_predictions': {
                'Ikan Bilis': round(confidence * 100, 2)
            }
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# New endpoints for user registration and authentication
@app.route('/api/register', methods=['POST'])
def register():
    try:
        data = request.json
        username = data.get('username')
        email = data.get('email')
        password = data.get('password')
        full_name = data.get('fullName')
        weight = data.get('weight')
        height = data.get('height')
        gender = data.get('gender')
        activity_level = data.get('activityLevel')
        
        if not all([username, email, password, full_name]):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Hash the password
        password_hash = hashlib.sha256(password.encode()).hexdigest()
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Check if username already exists
        cursor.execute("SELECT * FROM users WHERE username = %s", (username,))
        if cursor.fetchone():
            conn.close()
            return jsonify({'error': 'Username already exists'}), 409
        
        # Check if email already exists
        cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
        if cursor.fetchone():
            conn.close()
            return jsonify({'error': 'Email already exists'}), 409
        
        # Create the user with the new fields
        cursor.execute(
            """INSERT INTO users 
            (username, email, password_hash, full_name, weight, height, gender, activity_level) 
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)""",
            (username, email, password_hash, full_name, weight, height, gender, activity_level)
        )
        conn.commit()
        user_id = cursor.lastrowid
        
        conn.close()
        
        return jsonify({
            'id': user_id,
            'username': username,
            'email': email,
            'fullName': full_name,
            'weight': weight,
            'height': height,
            'gender': gender,
            'activityLevel': activity_level
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/login', methods=['POST'])
def login():
    try:
        data = request.json
        username = data.get('username')
        password = data.get('password')
        
        if not all([username, password]):
            return jsonify({'error': 'Missing username or password'}), 400
        
        # Hash the password for comparison
        password_hash = hashlib.sha256(password.encode()).hexdigest()
        
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Get user by username
        cursor.execute("SELECT * FROM users WHERE username = %s", (username,))
        user = cursor.fetchone()
        
        conn.close()
        
        if not user or user['password_hash'] != password_hash:
            return jsonify({'error': 'Invalid username or password'}), 401
        
        return jsonify({
            'id': user['id'],
            'username': user['username'],
            'email': user['email'],
            'fullName': user['full_name'],
            'weight': user['weight'],
            'height': user['height'],
            'gender': user['gender'],
            'activityLevel': user['activity_level']
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Food information endpoints
@app.route('/api/food-categories', methods=['GET'])
def get_food_categories():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("SELECT * FROM food_categories")
        categories = cursor.fetchall()
        
        conn.close()
        
        # Convert datetime objects to strings for JSON serialization
        for category in categories:
            if category.get('created_at'):
                category['created_at'] = category['created_at'].isoformat()
        
        return jsonify(categories), 200
        
    except Exception as e:
        print(f"Error in get_food_categories: {str(e)}")  # Debug print
        return jsonify({'error': str(e)}), 500

@app.route('/api/food-categories/<int:category_id>', methods=['GET'])
def get_food_category(category_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("SELECT * FROM food_categories WHERE id = %s", (category_id,))
        category = cursor.fetchone()
        
        conn.close()
        
        if category is None:
            return jsonify({'error': 'Category not found'}), 404
            
        if category.get('created_at'):
            category['created_at'] = category['created_at'].isoformat()
            
        return jsonify(category), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/food-info/<int:category_id>', methods=['GET'])
def get_food_info(category_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT 
                fc.id,
                fc.name,
                fc.description,
                fi.calories,
                fi.protein,
                fi.carbs,
                fi.fats,
                fi.description as nutritional_info,
                fi.cultural_info
            FROM food_categories fc
            LEFT JOIN food_info fi ON fc.id = fi.food_category_id
            WHERE fc.id = %s
        """, (category_id,))
        
        food_info = cursor.fetchone()
        conn.close()
        
        if food_info is None:
            return jsonify({'error': 'Food information not found'}), 404
            
        return jsonify(food_info), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/users/update', methods=['PUT'])
def update_user():
    try:
        data = request.json
        user_id = data.get('id')
        weight = data.get('weight')
        height = data.get('height')
        gender = data.get('gender')
        activity_level = data.get('activityLevel')
        full_name = data.get('fullName')
        
        if not user_id:
            return jsonify({'error': 'User ID is required'}), 400
        
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Update user information
        cursor.execute("""
            UPDATE users 
            SET weight = %s, height = %s, gender = %s, activity_level = %s, full_name = %s
            WHERE id = %s""", 
            (weight, height, gender, activity_level, full_name, user_id)
        )
        conn.commit()
        
        # Get updated user data
        cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
        user = cursor.fetchone()
        conn.close()
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
            
        return jsonify({
            'id': user['id'],
            'username': user['username'],
            'email': user['email'],
            'fullName': user['full_name'],
            'weight': user['weight'],
            'height': user['height'],
            'gender': user['gender'],
            'activityLevel': user['activity_level']
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Add a route for serving temporary images
@app.route('/temp_image/<path:filename>', methods=['GET'])
def temp_image(filename):
    return send_from_directory('uploads', filename)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)  # Added debug=True for better error messages
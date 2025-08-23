This mobile-based application uses AI to detect food from images and calculate calories automatically. It is specifically designed for traditional Malaysian dishes like Nasi Lemak, Laksa, and Ketupat.

## 👨‍💻 Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Python (Flask API)
- **AI Model**: TensorFlow + Roboflow (500 image dataset)
- **Database**: MySql

## 🚀 Features

- Detect food from image
- Calorie estimation per food item
- Supports multiple food items in one plate
- Meal history and tracking
- Specifically made for Malaysian Traditional Food

## 🛠️ Installation & Setup

1. Clone the repo:
   ```bash
   git clone https://github.com/Husnaisyam/fddc-app.git
   
2. Install Flutter and dependencies:
   ```bash
   flutter pub get

3. Go to the backend folder and install Flask:
   ```bash
   pip install flask

4. Change ip address in api_service.dart to your network ip address.
5. Run the Flask server:
   ```bash
   python server.py

6. Run the Flutter app:
   ```bash
   cd food_classifier_app
   flutter run

🤝 Acknowledgment
This project was developed by Nurul Husna Binti Mohd Badrulisyam under the supervision of Dr. Mohammed Gamal Ahmad Al Samman, Universiti Utara Malaysia, for the final year project in Software Engineering.
   

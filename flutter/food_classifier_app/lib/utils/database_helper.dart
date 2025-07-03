import 'package:mysql1/mysql1.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // Server IP - use your computer's actual IP address, not localhost
  final String serverIp = '172.20.10.3';

  // API base URL using the server IP
  String get baseApiUrl => 'http://$serverIp:5001/api';

  // For direct endpoints (not under /api path)
  String get serverUrl => 'http://$serverIp:5001';

  // Database configuration
  ConnectionSettings get _settings => ConnectionSettings(
        host: serverIp, // Use server IP instead of 'localhost'
        port: 3306,
        user: 'root',
        password: '',
        db: 'food_classifier_db',
      );

  // Get a database connection
  Future<MySqlConnection> getConnection() async {
    final connection = await MySqlConnection.connect(_settings);
    // Add delay to fix connection race condition bug
    await Future.delayed(Duration(seconds: 1));
    return connection;
  }

  // User Methods
  Future<Results> getUserByUsername(String username) async {
    final conn = await getConnection();
    final results =
        await conn.query('SELECT * FROM users WHERE username = ?', [username]);
    await conn.close();
    return results;
  }

  Future<Results> getUserById(int id) async {
    final conn = await getConnection();
    final results = await conn.query('SELECT * FROM users WHERE id = ?', [id]);
    await conn.close();
    return results;
  }

  Future<int> createUser(String username, String email, String passwordHash,
      String fullName) async {
    final conn = await getConnection();
    final result = await conn.query(
        'INSERT INTO users (username, email, password_hash, full_name) VALUES (?, ?, ?, ?)',
        [username, email, passwordHash, fullName]);
    await conn.close();
    return result.insertId ?? -1;
  }

  // Food Category Methods
  Future<Results> getAllFoodCategories() async {
    final conn = await getConnection();
    final results = await conn.query('SELECT * FROM food_categories');
    await conn.close();
    return results;
  }

  Future<Results> getFoodCategoryByName(String name) async {
    final conn = await getConnection();
    final results = await conn
        .query('SELECT * FROM food_categories WHERE name = ?', [name]);
    await conn.close();
    return results;
  }

  // Food Info Methods
  Future<Results> getFoodInfoByCategory(int categoryId) async {
    final conn = await getConnection();
    final results = await conn.query(
        'SELECT * FROM food_info WHERE food_category_id = ?', [categoryId]);
    await conn.close();
    return results;
  }

  // Prediction Methods - Using both direct database access and API
  // Original database method (for backward compatibility)
  Future<int> savePredictionToDatabase(int userId, int foodCategoryId,
      double confidence, String? imagePath) async {
    final conn = await getConnection();
    final result = await conn.query(
        'INSERT INTO food_predictions (user_id, food_category_id, confidence, image_path) VALUES (?, ?, ?, ?)',
        [userId, foodCategoryId, confidence, imagePath]);
    await conn.close();
    return result.insertId ?? -1;
  }

  // API method for saving predictions
  Future<Map<String, dynamic>> savePrediction(
      int userId, int foodId, double confidence, String? imagePath) async {
    try {
      // Use the baseApiUrl with consistent IP address
      final response = await http.post(
        Uri.parse('$baseApiUrl/predictions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'food_id': foodId,
          'confidence': confidence,
          'image_path': imagePath,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to save prediction: ${response.body}');
      }
    } catch (e) {
      print('API Error saving prediction: $e');
      // Fall back to database method if API fails
      final id =
          await savePredictionToDatabase(userId, foodId, confidence, imagePath);
      return {'id': id, 'message': 'Saved to database directly'};
    }
  }

  // Original database method for getting predictions
  Future<Results> getUserPredictionsFromDatabase(int userId) async {
    final conn = await getConnection();
    final results = await conn.query('''
      SELECT p.*, c.name as category_name 
      FROM food_predictions p
      JOIN food_categories c ON p.food_category_id = c.id
      WHERE p.user_id = ?
      ORDER BY p.created_at DESC
    ''', [userId]);
    await conn.close();
    return results;
  }

  // API method for getting user predictions
  Future<List<dynamic>> getUserPredictions(int userId) async {
    try {
      // Use the baseApiUrl with consistent IP address
      final response = await http.get(
        Uri.parse('$baseApiUrl/predictions/history/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get predictions: ${response.body}');
      }
    } catch (e) {
      print('API Error getting predictions: $e');
      // Fall back to database method
      final results = await getUserPredictionsFromDatabase(userId);
      // Convert to List<Map>
      return results
          .map((row) => {
                'id': row['id'],
                'user_id': row['user_id'],
                'food_category_id': row['food_category_id'],
                'confidence': row['confidence'],
                'image_path': row['image_path'],
                'created_at': row['created_at'].toString(),
                'category_name': row['category_name'],
              })
          .toList();
    }
  }
}

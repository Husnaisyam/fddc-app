import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_models.dart';

class ApiService {
  // Hardcoded server IP and port
  static const String baseUrl = 'http://172.20.10.3:5001/api';

  Future<List<FoodPrediction>> getUserPredictions(int userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/predictions/history/$userId'),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Connection timed out'),
          );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) {
          final prediction = FoodPrediction.fromJson(json);

          if (json['ingredients'] != null) {
            try {
              final List<dynamic> ingredientsList = json['ingredients'] as List;
              prediction.ingredients.addAll(
                  ingredientsList.map((i) => IngredientPrediction.fromJson(i)));
            } catch (e) {
              print('Error parsing ingredients: $e');
            }
          }

          return prediction;
        }).toList();
      } else {
        throw Exception('Failed to load predictions: ${response.statusCode}');
      }
    } catch (e) {
      print('Network error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> predictFood(
      int userId, String imageBase64) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'user_id': userId,
              'image': imageBase64,
              'include_side_dishes': true,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Image upload timed out'),
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['ingredients'] != null) {
          final List<dynamic> ingredients = data['ingredients'] as List;
          data['ingredients'] = ingredients
              .map((ingredient) => {
                    'name': ingredient['name'],
                    'confidence': ingredient['confidence'],
                  })
              .toList();
        }

        return data;
      } else {
        throw Exception('Failed to predict food: ${response.statusCode}');
      }
    } catch (e) {
      print('Network error during prediction: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserCalorieData(int userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/predictions/history/$userId'),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Connection timed out'),
          );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final predictions =
            data.map((json) => FoodPrediction.fromJson(json)).toList();

        // Get only predictions from today
        final now = DateTime.now();
        final todayPredictions = predictions
            .where((p) =>
                p.createdAt.year == now.year &&
                p.createdAt.month == now.month &&
                p.createdAt.day == now.day)
            .toList();

        // Calculate total calories consumed today
        double totalCalories = 0;
        final List<Map<String, dynamic>> calorieBreakdown = [];

        for (var prediction in todayPredictions) {
          if (prediction.calories != null) {
            totalCalories += prediction.calories!;
            calorieBreakdown.add({
              'foodName': prediction.foodName,
              'calories': prediction.calories,
              'time': prediction.createdAt,
              'imageUrl': prediction.imagePath,
            });
          }
        }

        return {
          'totalCalories': totalCalories,
          'predictions': todayPredictions,
          'calorieBreakdown': calorieBreakdown,
        };
      } else {
        throw Exception('Failed to load calorie data: ${response.statusCode}');
      }
    } catch (e) {
      print('Network error loading calorie data: $e');
      rethrow;
    }
  }
}

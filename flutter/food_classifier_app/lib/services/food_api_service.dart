import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_models.dart';

class FoodApiService {
  final String _baseUrl = 'http://172.20.10.3:5001'; // For Android emulator

  Future<List<FoodCategory>> getFoodCategories() async {
    try {
      final response =
          await http.get(Uri.parse('$_baseUrl/api/food-categories'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => FoodCategory.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load food categories');
      }
    } catch (e) {
      print('Error getting food categories: $e');
      rethrow;
    }
  }

  Future<FoodInfo> getFoodInfo(int categoryId) async {
    try {
      final response =
          await http.get(Uri.parse('$_baseUrl/api/food-info/$categoryId'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return FoodInfo.fromJson(data);
      } else {
        throw 'Failed to load food information';
      }
    } catch (e) {
      throw 'Error getting food info: $e';
    }
  }
}

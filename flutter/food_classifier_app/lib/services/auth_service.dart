import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class AuthService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _baseUrl = 'http://172.20.10.3:5001';

  // Register a new user with physical information
  Future<User?> register(
    String username,
    String email,
    String password,
    String fullName,
    double weight,
    double height,
    String gender,
    String activityLevel,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'fullName': fullName,
          'weight': weight,
          'height': height,
          'gender': gender,
          'activityLevel': activityLevel,
        }),
      );

      print('Registration response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return User(
          id: data['id'],
          username: data['username'],
          email: data['email'],
          fullName: data['fullName'],
          weight: data['weight'],
          height: data['height'],
          gender: data['gender'],
          activityLevel: data['activityLevel'],
        );
      } else {
        final error = jsonDecode(response.body)['error'];
        throw Exception(error);
      }
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }

  // Login user
  Future<User?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save user session
        await _secureStorage.write(
            key: 'user_id', value: data['id'].toString());
        await _secureStorage.write(key: 'username', value: data['username']);
        await _secureStorage.write(key: 'email', value: data['email']);
        await _secureStorage.write(key: 'fullName', value: data['fullName']);
        await _secureStorage.write(
            key: 'weight', value: data['weight'].toString());
        await _secureStorage.write(
            key: 'height', value: data['height'].toString());
        await _secureStorage.write(key: 'gender', value: data['gender']);
        await _secureStorage.write(
            key: 'activityLevel', value: data['activityLevel']);

        return User(
          id: data['id'],
          username: data['username'],
          email: data['email'],
          fullName: data['fullName'],
          weight: data['weight'],
          height: data['height'],
          gender: data['gender'],
          activityLevel: data['activityLevel'],
        );
      } else {
        return null;
      }
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      final userId = await _secureStorage.read(key: 'user_id');
      final username = await _secureStorage.read(key: 'username');
      final email = await _secureStorage.read(key: 'email');
      final fullName = await _secureStorage.read(key: 'fullName');
      final weight = await _secureStorage.read(key: 'weight');
      final height = await _secureStorage.read(key: 'height');
      final gender = await _secureStorage.read(key: 'gender');
      final activityLevel = await _secureStorage.read(key: 'activityLevel');

      if (userId == null || username == null) {
        return null;
      }

      return User(
        id: int.parse(userId),
        username: username,
        email: email ?? '',
        fullName: fullName ?? '',
        weight: weight != null ? double.parse(weight) : null,
        height: height != null ? double.parse(height) : null,
        gender: gender,
        activityLevel: activityLevel,
      );
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  // Update user profile
  Future<User?> updateProfile(
    int userId,
    String fullName,
    double? weight,
    double? height,
    String? gender,
    String? activityLevel,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/users/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': userId,
          'fullName': fullName,
          'weight': weight,
          'height': height,
          'gender': gender,
          'activityLevel': activityLevel,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Update stored user data
        await _secureStorage.write(key: 'fullName', value: data['fullName']);
        await _secureStorage.write(
            key: 'weight', value: data['weight']?.toString());
        await _secureStorage.write(
            key: 'height', value: data['height']?.toString());
        await _secureStorage.write(key: 'gender', value: data['gender']);
        await _secureStorage.write(
            key: 'activityLevel', value: data['activityLevel']);

        return User(
          id: data['id'],
          username: data['username'],
          email: data['email'],
          fullName: data['fullName'],
          weight: data['weight']?.toDouble(),
          height: data['height']?.toDouble(),
          gender: data['gender'],
          activityLevel: data['activityLevel'],
        );
      } else {
        final error = jsonDecode(response.body)['error'];
        throw Exception(error);
      }
    } catch (e) {
      print('Update profile error: $e');
      rethrow;
    }
  }

  // Logout user
  Future<void> logout() async {
    await _secureStorage.deleteAll();
  }
}

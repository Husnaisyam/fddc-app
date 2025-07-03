class User {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final double? weight; // in kg
  final double? height; // in cm
  final String? gender;
  final String? activityLevel;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.weight,
    this.height,
    this.gender,
    this.activityLevel,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      fullName: map['full_name'] ?? '',
      weight:
          map['weight'] != null ? double.parse(map['weight'].toString()) : null,
      height:
          map['height'] != null ? double.parse(map['height'].toString()) : null,
      gender: map['gender'],
      activityLevel: map['activity_level'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'weight': weight,
      'height': height,
      'gender': gender,
      'activity_level': activityLevel,
    };
  }

  // Calculate BMI
  double? calculateBMI() {
    if (weight == null || height == null || height == 0) {
      return null;
    }
    // Convert height from cm to m
    final heightInMeters = height! / 100.0;
    return weight! / (heightInMeters * heightInMeters);
  }

  // Get BMI category
  String getBMICategory() {
    final bmi = calculateBMI();
    if (bmi == null) return 'Not available';

    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi < 25) {
      return 'Normal weight';
    } else if (bmi < 30) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }

  // Get recommended daily calorie intake
  double? calculateDailyCalories() {
    if (weight == null ||
        height == null ||
        gender == null ||
        activityLevel == null) {
      return null;
    }

    // Base BMR calculation using Mifflin-St Jeor Equation
    double bmr;
    if (gender == 'male') {
      bmr =
          10 * weight! + 6.25 * height! - 5 * 25 + 5; // Assuming age 25 for now
    } else {
      bmr = 10 * weight! + 6.25 * height! - 5 * 25 - 161;
    }

    // Activity multipliers
    final multipliers = {
      'sedentary': 1.2,
      'lightly_active': 1.375,
      'moderately_active': 1.55,
      'very_active': 1.725,
      'extremely_active': 1.9,
    };

    return bmr * (multipliers[activityLevel] ?? 1.2);
  }
}
